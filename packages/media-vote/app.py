#!/usr/bin/env python3
"""Media Vote: a small Jellyfin-backed voting companion."""

from __future__ import annotations

import fcntl
import json
import os
import secrets
import sqlite3
import sys
import threading
import time
from collections import defaultdict
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from flask import Flask, Response, g, jsonify, render_template, request


APP_NAME = "Media Vote"
APP_VERSION = "0.1.0"
VOTE_CHOICES = {"archive", "delete", "dontcare", "quality"}
VOTABLE_TYPES = {"Movie", "Series", "Season"}
SESSION_TTL = 60 * 60 * 24 * 14
VISIBILITY_TTL = 60 * 5
SYNC_PAGE_SIZE = 250


class JellyfinError(RuntimeError):
    pass


class JellyfinClient:
    def __init__(self, base_url: str, api_key_file: str | None = None):
        self.base_url = base_url.rstrip("/")
        self.api_key_file = api_key_file

    @staticmethod
    def _authorization(token: str | None = None) -> str:
        fields = (
            f'Client="{APP_NAME}", Device="Web", '
            f'DeviceId="media-vote", Version="{APP_VERSION}"'
        )
        if token:
            return f'MediaBrowser Token="{token}", {fields}'
        return f"MediaBrowser {fields}"

    def request(
        self,
        method: str,
        path: str,
        *,
        token: str | None = None,
        service: bool = False,
        body: dict[str, Any] | None = None,
        query: dict[str, Any] | None = None,
        raw: bool = False,
    ) -> Any:
        url = f"{self.base_url}{path}"
        if query:
            url = f"{url}?{urlencode(query)}"
        data = json.dumps(body).encode() if body is not None else None
        service_token = None
        if service:
            if not self.api_key_file:
                raise JellyfinError("Jellyfin service key is not configured")
            try:
                service_token = Path(self.api_key_file).read_text().strip()
            except OSError as error:
                raise JellyfinError("Jellyfin service key is unavailable") from error
            if not service_token:
                raise JellyfinError("Jellyfin service key is empty")
        auth_token = service_token or token
        headers = {
            "Accept": "application/json",
            "Authorization": self._authorization(auth_token),
        }
        if service_token:
            headers["X-Emby-Token"] = service_token
        if data is not None:
            headers["Content-Type"] = "application/json"
        req = Request(url, data=data, headers=headers, method=method)
        try:
            with urlopen(req, timeout=30) as response:
                payload = response.read()
                if raw:
                    return payload, response.headers.get_content_type()
                return json.loads(payload) if payload else {}
        except HTTPError as error:
            if error.code in (401, 403):
                raise JellyfinError("Jellyfin rejected the credentials") from error
            raise JellyfinError(f"Jellyfin returned HTTP {error.code}") from error
        except (URLError, TimeoutError) as error:
            raise JellyfinError("Jellyfin is currently unreachable") from error

    def authenticate(self, username: str, password: str) -> dict[str, Any]:
        return self.request(
            "POST",
            "/Users/AuthenticateByName",
            body={"Username": username, "Pw": password},
        )

    def visible_item_ids(self, user_id: str, token: str) -> set[str]:
        result = self.request(
            "GET",
            f"/Users/{user_id}/Items",
            token=token,
            query={
                "Recursive": "true",
                "IncludeItemTypes": "Movie,Series,Season",
                "StartIndex": 0,
                "Limit": 100000,
            },
        )
        return {item["Id"] for item in result.get("Items", []) if item.get("Id")}

    def paged_items(
        self,
        *,
        item_types: str,
        fields: str,
        page_size: int = SYNC_PAGE_SIZE,
    ) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        start_index = 0
        while True:
            result = self.request(
                "GET",
                "/Items",
                service=True,
                query={
                    "Recursive": "true",
                    "IncludeItemTypes": item_types,
                    "Fields": fields,
                    "EnableImages": "true",
                    "ImageTypeLimit": 1,
                    "StartIndex": start_index,
                    "Limit": page_size,
                    "SortBy": "SortName",
                    "SortOrder": "Ascending",
                },
            )
            page = result.get("Items", [])
            items.extend(page)
            start_index += len(page)
            total = int(result.get("TotalRecordCount") or len(items))
            if not page or start_index >= total:
                break
        return items

    def sync_items(self, page_size: int = SYNC_PAGE_SIZE) -> list[dict[str, Any]]:
        scopes = self.paged_items(
            item_types="Movie,Series,Season",
            fields="Overview,ProductionYear,ProviderIds",
            page_size=page_size,
        )
        leaves = self.paged_items(
            item_types="Movie,Episode",
            fields=(
                "MediaSources,MediaStreams,Path,ProductionYear,"
                "ProviderIds"
            ),
            page_size=page_size,
        )
        by_id = {item["Id"]: item for item in scopes if item.get("Id")}
        for item in leaves:
            if item.get("Type") == "Movie" and item.get("Id") in by_id:
                by_id[item["Id"]].update(item)
            else:
                by_id[item["Id"]] = item
        return list(by_id.values())

    def image(self, item_id: str) -> tuple[bytes, str]:
        return self.request(
            "GET",
            f"/Items/{item_id}/Images/Primary",
            service=True,
            query={"maxWidth": 600, "quality": 85},
            raw=True,
        )


@dataclass
class Session:
    sid: str
    csrf: str
    token: str
    user_id: str
    username: str
    is_admin: bool
    expires_at: float


class SessionStore:
    def __init__(self):
        self._sessions: dict[str, Session] = {}
        self._lock = threading.Lock()

    def create(
        self, token: str, user_id: str, username: str, is_admin: bool
    ) -> Session:
        session = Session(
            sid=secrets.token_urlsafe(32),
            csrf=secrets.token_urlsafe(24),
            token=token,
            user_id=user_id,
            username=username,
            is_admin=is_admin,
            expires_at=time.time() + SESSION_TTL,
        )
        with self._lock:
            self._sessions[session.sid] = session
        return session

    def get(self, sid: str | None) -> Session | None:
        if not sid:
            return None
        now = time.time()
        with self._lock:
            session = self._sessions.get(sid)
            if not session or session.expires_at <= now:
                self._sessions.pop(sid, None)
                return None
            session.expires_at = now + SESSION_TTL
            return session

    def remove(self, sid: str | None) -> None:
        if sid:
            with self._lock:
                self._sessions.pop(sid, None)


class VoteStore:
    def __init__(self, db_path: str):
        self.db_path = db_path
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        self._initialize()

    def connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.db_path)
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute("PRAGMA journal_mode = WAL")
        connection.execute("PRAGMA busy_timeout = 5000")
        return connection

    @contextmanager
    def connection(self):
        connection = self.connect()
        try:
            with connection:
                yield connection
        finally:
            connection.close()

    def _initialize(self) -> None:
        with self.connection() as db:
            db.executescript(
                """
                CREATE TABLE IF NOT EXISTS votes (
                    user_id TEXT NOT NULL,
                    username TEXT NOT NULL,
                    item_id TEXT NOT NULL,
                    item_type TEXT NOT NULL,
                    item_name TEXT NOT NULL,
                    parent_name TEXT,
                    choice TEXT NOT NULL,
                    size_bytes INTEGER NOT NULL DEFAULT 0,
                    updated_at INTEGER NOT NULL,
                    PRIMARY KEY (user_id, item_id)
                );

                CREATE TABLE IF NOT EXISTS admin_reviews (
                    item_id TEXT PRIMARY KEY,
                    status TEXT NOT NULL DEFAULT 'open',
                    reviewed_by TEXT,
                    updated_at INTEGER NOT NULL
                );

                CREATE TABLE IF NOT EXISTS catalog_items (
                    item_id TEXT PRIMARY KEY,
                    data_json TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS catalog_files (
                    file_id TEXT PRIMARY KEY,
                    data_json TEXT NOT NULL
                );

                CREATE TABLE IF NOT EXISTS sync_state (
                    singleton INTEGER PRIMARY KEY CHECK (singleton = 1),
                    status TEXT NOT NULL,
                    started_at INTEGER,
                    succeeded_at INTEGER,
                    error TEXT,
                    item_count INTEGER NOT NULL DEFAULT 0,
                    file_count INTEGER NOT NULL DEFAULT 0
                );

                INSERT OR IGNORE INTO sync_state (
                    singleton, status, item_count, file_count
                ) VALUES (1, 'never', 0, 0);

                CREATE INDEX IF NOT EXISTS votes_item_id_idx ON votes(item_id);
                CREATE INDEX IF NOT EXISTS votes_choice_idx ON votes(choice);
                """
            )

    def catalog(self) -> dict[str, list[dict[str, Any]]]:
        with self.connection() as db:
            item_rows = db.execute(
                "SELECT data_json FROM catalog_items"
            ).fetchall()
            file_rows = db.execute(
                "SELECT data_json FROM catalog_files"
            ).fetchall()
        catalog = {
            "items": [json.loads(row["data_json"]) for row in item_rows],
            "files": [json.loads(row["data_json"]) for row in file_rows],
        }
        catalog["files"].sort(
            key=lambda item: item.get("sizeBytes", 0),
            reverse=True,
        )
        return catalog

    def replace_catalog(self, catalog: dict[str, Any], started_at: int) -> None:
        succeeded_at = int(time.time())
        with self.connection() as db:
            db.execute("DELETE FROM catalog_items")
            db.execute("DELETE FROM catalog_files")
            db.executemany(
                "INSERT INTO catalog_items (item_id, data_json) VALUES (?, ?)",
                [
                    (
                        item["id"],
                        json.dumps(item, separators=(",", ":"), sort_keys=True),
                    )
                    for item in catalog["items"]
                ],
            )
            db.executemany(
                "INSERT INTO catalog_files (file_id, data_json) VALUES (?, ?)",
                [
                    (
                        item["id"],
                        json.dumps(item, separators=(",", ":"), sort_keys=True),
                    )
                    for item in catalog["files"]
                ],
            )
            db.execute(
                """
                UPDATE sync_state
                SET status = 'ready',
                    started_at = ?,
                    succeeded_at = ?,
                    error = NULL,
                    item_count = ?,
                    file_count = ?
                WHERE singleton = 1
                """,
                (
                    started_at,
                    succeeded_at,
                    len(catalog["items"]),
                    len(catalog["files"]),
                ),
            )

    def mark_sync_started(self, started_at: int) -> None:
        with self.connection() as db:
            db.execute(
                """
                UPDATE sync_state
                SET status = 'running', started_at = ?, error = NULL
                WHERE singleton = 1
                """,
                (started_at,),
            )

    def mark_sync_failed(self, started_at: int, error: str) -> None:
        with self.connection() as db:
            db.execute(
                """
                UPDATE sync_state
                SET status = 'error', started_at = ?, error = ?
                WHERE singleton = 1
                """,
                (started_at, error[:300]),
            )

    def sync_status(self) -> dict[str, Any]:
        with self.connection() as db:
            row = db.execute(
                """
                SELECT status, started_at, succeeded_at, error,
                       item_count, file_count
                FROM sync_state
                WHERE singleton = 1
                """
            ).fetchone()
        return {
            "status": row["status"],
            "startedAt": row["started_at"],
            "succeededAt": row["succeeded_at"],
            "error": row["error"],
            "itemCount": row["item_count"],
            "fileCount": row["file_count"],
        }

    def votes_for_user(self, user_id: str) -> dict[str, str]:
        with self.connection() as db:
            rows = db.execute(
                "SELECT item_id, choice FROM votes WHERE user_id = ?", (user_id,)
            ).fetchall()
        return {row["item_id"]: row["choice"] for row in rows}

    def cast(
        self,
        *,
        session: Session,
        item: dict[str, Any],
        choice: str | None,
    ) -> None:
        with self.connection() as db:
            if choice is None:
                db.execute(
                    "DELETE FROM votes WHERE user_id = ? AND item_id = ?",
                    (session.user_id, item["id"]),
                )
                return
            db.execute(
                """
                INSERT INTO votes (
                    user_id, username, item_id, item_type, item_name,
                    parent_name, choice, size_bytes, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(user_id, item_id) DO UPDATE SET
                    username = excluded.username,
                    item_type = excluded.item_type,
                    item_name = excluded.item_name,
                    parent_name = excluded.parent_name,
                    choice = excluded.choice,
                    size_bytes = excluded.size_bytes,
                    updated_at = excluded.updated_at
                """,
                (
                    session.user_id,
                    session.username,
                    item["id"],
                    item["type"],
                    item["name"],
                    item.get("parentName"),
                    choice,
                    item.get("sizeBytes", 0),
                    int(time.time()),
                ),
            )

    def shortlist(self, include_resolved: bool = False) -> list[dict[str, Any]]:
        with self.connection() as db:
            rows = db.execute(
                """
                SELECT v.*, COALESCE(r.status, 'open') AS review_status
                FROM votes v
                LEFT JOIN admin_reviews r ON r.item_id = v.item_id
                ORDER BY v.updated_at DESC
                """
            ).fetchall()

        grouped: dict[str, dict[str, Any]] = {}
        for row in rows:
            if not include_resolved and row["review_status"] != "open":
                continue
            item = grouped.setdefault(
                row["item_id"],
                {
                    "id": row["item_id"],
                    "name": row["item_name"],
                    "type": row["item_type"],
                    "parentName": row["parent_name"],
                    "sizeBytes": row["size_bytes"],
                    "status": row["review_status"],
                    "votes": defaultdict(list),
                    "latest": 0,
                },
            )
            item["votes"][row["choice"]].append(row["username"])
            item["latest"] = max(item["latest"], row["updated_at"])

        shortlist = []
        for item in grouped.values():
            votes = item["votes"]
            delete_count = len(votes["delete"])
            archive_count = len(votes["archive"])
            quality_count = len(votes["quality"])
            if delete_count and archive_count:
                recommendation, rank = "conflict", 0
            elif delete_count:
                recommendation, rank = "delete", 1
            elif quality_count:
                recommendation, rank = "quality", 2
            elif archive_count:
                recommendation, rank = "protect", 3
            else:
                continue
            item["recommendation"] = recommendation
            item["counts"] = {
                choice: len(votes[choice])
                for choice in ("archive", "delete", "quality", "dontcare")
            }
            item["voters"] = {
                choice: sorted(votes[choice])
                for choice in ("archive", "delete", "quality", "dontcare")
                if votes[choice]
            }
            item["_rank"] = rank
            del item["votes"]
            shortlist.append(item)

        shortlist.sort(
            key=lambda item: (
                item["_rank"],
                -sum(item["counts"].values()),
                -item["sizeBytes"],
                item["name"].casefold(),
            )
        )
        for item in shortlist:
            del item["_rank"]
        return shortlist

    def set_review(self, item_id: str, status: str, username: str) -> None:
        with self.connection() as db:
            db.execute(
                """
                INSERT INTO admin_reviews (item_id, status, reviewed_by, updated_at)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(item_id) DO UPDATE SET
                    status = excluded.status,
                    reviewed_by = excluded.reviewed_by,
                    updated_at = excluded.updated_at
                """,
                (item_id, status, username, int(time.time())),
            )


def _source_stats(source: dict[str, Any]) -> dict[str, Any]:
    streams = source.get("MediaStreams") or []
    video = next((stream for stream in streams if stream.get("Type") == "Video"), {})
    runtime_ticks = source.get("RunTimeTicks") or 0
    return {
        "sizeBytes": int(source.get("Size") or 0),
        "runtimeTicks": int(runtime_ticks),
        "height": int(video.get("Height") or 0),
        "width": int(video.get("Width") or 0),
        "codec": (video.get("Codec") or "").upper(),
        "bitrate": int(source.get("Bitrate") or video.get("BitRate") or 0),
        "path": source.get("Path") or "",
    }


def _item_stats(item: dict[str, Any]) -> dict[str, Any]:
    sources = item.get("MediaSources") or []
    stats = [_source_stats(source) for source in sources]
    if not stats:
        return {
            "sizeBytes": 0,
            "runtimeTicks": int(item.get("RunTimeTicks") or 0),
            "height": 0,
            "width": 0,
            "codecs": [],
            "bitrate": 0,
            "paths": [],
            "fileCount": 0,
        }
    return {
        "sizeBytes": sum(stat["sizeBytes"] for stat in stats),
        "runtimeTicks": max(stat["runtimeTicks"] for stat in stats),
        "height": max(stat["height"] for stat in stats),
        "width": max(stat["width"] for stat in stats),
        "codecs": sorted({stat["codec"] for stat in stats if stat["codec"]}),
        "bitrate": max(stat["bitrate"] for stat in stats),
        "paths": [stat["path"] for stat in stats if stat["path"]],
        "fileCount": len(stats),
    }


def _merge_stats(target: dict[str, Any], source: dict[str, Any]) -> None:
    target["sizeBytes"] += source["sizeBytes"]
    target["runtimeTicks"] += source["runtimeTicks"]
    target["height"] = max(target["height"], source["height"])
    target["width"] = max(target["width"], source["width"])
    target["bitrate"] = max(target["bitrate"], source["bitrate"])
    target["fileCount"] += source["fileCount"]
    target["_codecs"].update(source["codecs"])


def normalize_catalog(raw_items: list[dict[str, Any]]) -> dict[str, Any]:
    raw_by_id = {item["Id"]: item for item in raw_items if item.get("Id")}
    entries: dict[str, dict[str, Any]] = {}
    files = []

    for raw in raw_items:
        item_type = raw.get("Type")
        if item_type not in VOTABLE_TYPES:
            continue
        parent_name = raw.get("SeriesName")
        if not parent_name and raw.get("SeriesId") in raw_by_id:
            parent_name = raw_by_id[raw["SeriesId"]].get("Name")
        stats = _item_stats(raw)
        image_tags = raw.get("ImageTags") or {}
        image_tag = image_tags.get("Primary") or raw.get("ParentPrimaryImageTag")
        image_id = (
            raw["Id"]
            if image_tags.get("Primary")
            else raw.get("ParentPrimaryImageItemId")
        )
        entries[raw["Id"]] = {
            "id": raw["Id"],
            "name": raw.get("Name") or "Untitled",
            "sortName": raw.get("SortName") or raw.get("Name") or "Untitled",
            "type": item_type,
            "parentId": raw.get("SeriesId") if item_type == "Season" else None,
            "parentName": parent_name,
            "year": raw.get("ProductionYear"),
            "overview": raw.get("Overview") or "",
            "imageTag": image_tag,
            "imageId": image_id,
            **stats,
            "_codecs": set(stats["codecs"]),
        }

    for raw in raw_items:
        if raw.get("Type") not in {"Movie", "Episode"}:
            continue
        stats = _item_stats(raw)
        series_name = raw.get("SeriesName") or ""
        season_name = raw.get("SeasonName") or ""
        label = raw.get("Name") or "Untitled"
        if raw.get("Type") == "Episode":
            episode = raw.get("IndexNumber")
            season = raw.get("ParentIndexNumber")
            code = ""
            if season is not None and episode is not None:
                code = f"S{int(season):02d}E{int(episode):02d} · "
            label = f"{series_name} · {code}{label}".strip(" ·")
        sources = raw.get("MediaSources") or []
        for index, source in enumerate(sources):
            source_stats = _source_stats(source)
            source_name = source.get("Name") if len(sources) > 1 else None
            files.append(
                {
                    "id": f"{raw['Id']}:{index}",
                    "name": f"{label} · {source_name}" if source_name else label,
                    "type": raw.get("Type"),
                    "scopeId": raw.get("SeasonId")
                    or raw.get("SeriesId")
                    or raw["Id"],
                    "seriesName": series_name,
                    "seasonName": season_name,
                    "sizeBytes": source_stats["sizeBytes"],
                    "runtimeTicks": source_stats["runtimeTicks"],
                    "height": source_stats["height"],
                    "width": source_stats["width"],
                    "codecs": (
                        [source_stats["codec"]] if source_stats["codec"] else []
                    ),
                    "bitrate": source_stats["bitrate"],
                    "paths": [source_stats["path"]] if source_stats["path"] else [],
                    "fileCount": 1,
                }
            )
        if raw.get("Type") != "Episode":
            continue
        season_entry = entries.get(raw.get("SeasonId"))
        series_entry = entries.get(raw.get("SeriesId"))
        if season_entry:
            _merge_stats(season_entry, stats)
        if series_entry:
            _merge_stats(series_entry, stats)

    for entry in entries.values():
        entry["codecs"] = sorted(entry.pop("_codecs"))
        if entry["runtimeTicks"]:
            hours = entry["runtimeTicks"] / 10_000_000 / 3600
            entry["bytesPerHour"] = round(entry["sizeBytes"] / hours) if hours else 0
        else:
            entry["bytesPerHour"] = 0
        entry.pop("paths", None)

    for file in files:
        if file["runtimeTicks"]:
            hours = file["runtimeTicks"] / 10_000_000 / 3600
            file["bytesPerHour"] = round(file["sizeBytes"] / hours) if hours else 0
        else:
            file["bytesPerHour"] = 0
        paths = file.pop("paths", [])
        file["path"] = paths[0] if paths else ""

    return {
        "items": sorted(
            entries.values(),
            key=lambda item: (
                {"Movie": 0, "Series": 1, "Season": 2}[item["type"]],
                item["sortName"].casefold(),
            ),
        ),
        "files": sorted(files, key=lambda item: item["sizeBytes"], reverse=True),
    }


class CatalogSynchronizer:
    def __init__(
        self,
        jellyfin: JellyfinClient,
        store: VoteStore,
        lock_path: str,
        page_size: int = SYNC_PAGE_SIZE,
    ):
        self.jellyfin = jellyfin
        self.store = store
        self.lock_path = lock_path
        self.page_size = page_size
        self._thread_lock = threading.Lock()

    def run(self) -> bool:
        Path(self.lock_path).parent.mkdir(parents=True, exist_ok=True)
        with open(self.lock_path, "a+", encoding="utf-8") as lock_file:
            try:
                fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return False
            started_at = int(time.time())
            self.store.mark_sync_started(started_at)
            try:
                raw_items = self.jellyfin.sync_items(self.page_size)
                catalog = normalize_catalog(raw_items)
                self.store.replace_catalog(catalog, started_at)
            except Exception as error:
                message = (
                    str(error)
                    if isinstance(error, JellyfinError)
                    else "Catalog synchronization failed"
                )
                self.store.mark_sync_failed(started_at, message)
                raise
            finally:
                fcntl.flock(lock_file, fcntl.LOCK_UN)
        return True

    def start_background(self) -> bool:
        if not self._thread_lock.acquire(blocking=False):
            return False

        def worker() -> None:
            try:
                self.run()
            finally:
                self._thread_lock.release()

        threading.Thread(
            target=worker,
            name="media-vote-catalog-sync",
            daemon=True,
        ).start()
        return True


def create_app(
    test_config: dict[str, Any] | None = None,
    jellyfin_client: JellyfinClient | None = None,
) -> Flask:
    app = Flask(__name__)
    app.config.update(
        DATABASE=os.environ.get(
            "MEDIA_VOTE_DATABASE", "/tmp/media-vote.sqlite"
        ),
        JELLYFIN_URL=os.environ.get(
            "MEDIA_VOTE_JELLYFIN_URL", "http://127.0.0.1:8096"
        ),
        JELLYFIN_API_KEY_FILE=os.environ.get(
            "MEDIA_VOTE_JELLYFIN_API_KEY_FILE"
        ),
        SYNC_LOCK=os.environ.get(
            "MEDIA_VOTE_SYNC_LOCK", "/tmp/media-vote-sync.lock"
        ),
        SYNC_ON_START=False,
        SYNC_PAGE_SIZE=SYNC_PAGE_SIZE,
        ADMIN_USERNAME=os.environ.get("MEDIA_VOTE_ADMIN_USERNAME", "juicy"),
        SESSION_COOKIE_NAME="media_vote_session",
    )
    if test_config:
        app.config.update(test_config)

    sessions = SessionStore()
    votes = VoteStore(app.config["DATABASE"])
    jellyfin = jellyfin_client or JellyfinClient(
        app.config["JELLYFIN_URL"],
        app.config["JELLYFIN_API_KEY_FILE"],
    )
    synchronizer = CatalogSynchronizer(
        jellyfin,
        votes,
        app.config["SYNC_LOCK"],
        app.config["SYNC_PAGE_SIZE"],
    )
    visibility_cache: dict[str, tuple[float, set[str]]] = {}
    cache_lock = threading.Lock()
    app.extensions["media_vote_sync"] = synchronizer
    app.extensions["media_vote_store"] = votes

    if app.config["SYNC_ON_START"]:
        synchronizer.run()

    def current_session() -> Session | None:
        return sessions.get(request.cookies.get(app.config["SESSION_COOKIE_NAME"]))

    def require_session(admin: bool = False) -> Session | Response:
        session = current_session()
        if not session:
            return jsonify({"error": "Login required"}), 401
        if admin and not session.is_admin:
            return jsonify({"error": "Admin access required"}), 403
        if request.method not in {"GET", "HEAD", "OPTIONS"}:
            if request.headers.get("X-CSRF-Token") != session.csrf:
                return jsonify({"error": "Invalid request token"}), 403
        g.media_session = session
        return session

    def visible_item_ids(session: Session, refresh: bool = False) -> set[str]:
        now = time.time()
        with cache_lock:
            cached = visibility_cache.get(session.user_id)
        if cached and not refresh and cached[0] > now:
            return cached[1]
        visible = jellyfin.visible_item_ids(session.user_id, session.token)
        with cache_lock:
            visibility_cache[session.user_id] = (
                now + VISIBILITY_TTL,
                visible,
            )
        return visible

    def catalog_for(session: Session, refresh: bool = False) -> dict[str, Any]:
        catalog = votes.catalog()
        if not catalog["items"]:
            raise JellyfinError(
                "The catalog has not finished its first synchronization"
            )
        allowed = (
            {item["id"] for item in catalog["items"]}
            if session.is_admin
            else visible_item_ids(session, refresh)
        )
        items = [item for item in catalog["items"] if item["id"] in allowed]
        items.sort(
            key=lambda item: (
                {"Movie": 0, "Series": 1, "Season": 2}[item["type"]],
                item["sortName"].casefold(),
            )
        )
        return {"items": items, "files": catalog["files"]}

    @app.after_request
    def security_headers(response: Response) -> Response:
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; img-src 'self' data:; "
            "style-src 'self'; script-src 'self'; connect-src 'self'; "
            "frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
        )
        response.headers["Referrer-Policy"] = "same-origin"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        return response

    @app.get("/")
    def index() -> str:
        return render_template("index.html")

    @app.get("/health")
    def health() -> Response:
        return jsonify({"status": "ok"})

    @app.get("/api/session")
    def session_info() -> Response:
        session = current_session()
        if not session:
            return jsonify({"authenticated": False})
        return jsonify(
            {
                "authenticated": True,
                "username": session.username,
                "isAdmin": session.is_admin,
                "csrf": session.csrf,
            }
        )

    @app.post("/api/login")
    def login() -> Response:
        payload = request.get_json(silent=True) or {}
        username = str(payload.get("username") or "").strip()
        password = str(payload.get("password") or "")
        if not username or not password:
            return jsonify({"error": "Enter your Jellyfin username and password"}), 400
        try:
            auth = jellyfin.authenticate(username, password)
        except JellyfinError as error:
            return jsonify({"error": str(error)}), 401
        user = auth.get("User") or {}
        token = auth.get("AccessToken")
        user_id = user.get("Id")
        canonical_name = user.get("Name") or username
        if not token or not user_id:
            return jsonify({"error": "Jellyfin returned an incomplete login"}), 502
        session = sessions.create(
            token=token,
            user_id=user_id,
            username=canonical_name,
            is_admin=canonical_name.casefold()
            == app.config["ADMIN_USERNAME"].casefold(),
        )
        response = jsonify(
            {
                "authenticated": True,
                "username": session.username,
                "isAdmin": session.is_admin,
                "csrf": session.csrf,
            }
        )
        response.set_cookie(
            app.config["SESSION_COOKIE_NAME"],
            session.sid,
            max_age=SESSION_TTL,
            httponly=True,
            samesite="Lax",
            secure=request.is_secure,
        )
        return response

    @app.post("/api/logout")
    def logout() -> Response:
        result = require_session()
        if not isinstance(result, Session):
            return result
        sessions.remove(result.sid)
        response = jsonify({"authenticated": False})
        response.delete_cookie(app.config["SESSION_COOKIE_NAME"])
        return response

    @app.get("/api/catalog")
    def catalog() -> Response:
        result = require_session()
        if not isinstance(result, Session):
            return result
        try:
            library = catalog_for(
                result, refresh=request.args.get("refresh") == "true"
            )
        except JellyfinError as error:
            return jsonify({"error": str(error)}), 502
        user_votes = votes.votes_for_user(result.user_id)
        items = []
        for item in library["items"]:
            safe_item = {
                key: value
                for key, value in item.items()
                if key not in {"sortName"}
            }
            safe_item["vote"] = user_votes.get(item["id"])
            items.append(safe_item)
        return jsonify(
            {
                "items": items,
                "sync": votes.sync_status(),
                "refreshedAt": int(time.time()),
            }
        )

    @app.post("/api/votes")
    def cast_vote() -> Response:
        result = require_session()
        if not isinstance(result, Session):
            return result
        payload = request.get_json(silent=True) or {}
        choice = payload.get("choice")
        if choice == "clear":
            choice = None
        if choice is not None and choice not in VOTE_CHOICES:
            return jsonify({"error": "Unknown vote"}), 400
        item_id = str(payload.get("itemId") or "")
        try:
            library = catalog_for(result)
        except JellyfinError as error:
            return jsonify({"error": str(error)}), 502
        item = next(
            (candidate for candidate in library["items"] if candidate["id"] == item_id),
            None,
        )
        if not item or item["type"] not in VOTABLE_TYPES:
            return jsonify({"error": "That item is not votable"}), 404
        votes.cast(session=result, item=item, choice=choice)
        return jsonify({"itemId": item_id, "choice": choice})

    @app.get("/api/images/<item_id>")
    def image(item_id: str) -> Response:
        result = require_session()
        if not isinstance(result, Session):
            return result
        try:
            catalog = catalog_for(result)
            allowed_images = {
                item.get("imageId")
                for item in catalog["items"]
                if item.get("imageId")
            }
            if item_id not in allowed_images:
                return Response(status=404)
            payload, content_type = jellyfin.image(item_id)
        except JellyfinError:
            return Response(status=404)
        response = Response(payload, content_type=content_type)
        response.headers["Cache-Control"] = "private, max-age=86400"
        return response

    @app.get("/api/admin/shortlist")
    def admin_shortlist() -> Response:
        result = require_session(admin=True)
        if not isinstance(result, Session):
            return result
        include_resolved = request.args.get("resolved") == "true"
        return jsonify({"items": votes.shortlist(include_resolved)})

    @app.get("/api/sync-status")
    def sync_status() -> Response:
        result = require_session()
        if not isinstance(result, Session):
            return result
        return jsonify(votes.sync_status())

    @app.post("/api/admin/sync")
    def admin_sync() -> Response:
        result = require_session(admin=True)
        if not isinstance(result, Session):
            return result
        if not synchronizer.start_background():
            return jsonify({"error": "A catalog sync is already running"}), 409
        return jsonify({"status": "started"}), 202

    @app.post("/api/admin/reviews")
    def admin_review() -> Response:
        result = require_session(admin=True)
        if not isinstance(result, Session):
            return result
        payload = request.get_json(silent=True) or {}
        item_id = str(payload.get("itemId") or "")
        status = str(payload.get("status") or "")
        if not item_id or status not in {"open", "reviewed", "dismissed"}:
            return jsonify({"error": "Invalid review update"}), 400
        votes.set_review(item_id, status, result.username)
        return jsonify({"itemId": item_id, "status": status})

    @app.get("/api/admin/storage")
    def admin_storage() -> Response:
        result = require_session(admin=True)
        if not isinstance(result, Session):
            return result
        library = votes.catalog()
        limit = min(max(int(request.args.get("limit", 100)), 1), 500)
        return jsonify({"files": library["files"][:limit]})

    return app


app = create_app()


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "sync":
        completed = app.extensions["media_vote_sync"].run()
        raise SystemExit(0 if completed else 75)
    app.run(host="127.0.0.1", port=8787)
