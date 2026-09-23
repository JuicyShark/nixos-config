#!/usr/bin/env python3
"""Stable Home Assistant presence state from small, reload-safe source facts."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import sys
import threading
import time
from typing import Any

from paho.mqtt import client as mqtt


STATES = (
    "gaming",
    "locked",
    "streaming",
    "remote-streaming",
    "screen-recording",
)


def atomic_json(path: Path, value: Any) -> None:
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(value, handle, sort_keys=True)
            handle.write("\n")
        temporary.replace(path)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def runtime_directory(explicit: str | None = None) -> Path:
    if explicit:
        return Path(explicit)
    base = os.environ.get("XDG_RUNTIME_DIR")
    if not base:
        raise RuntimeError("XDG_RUNTIME_DIR is not set")
    return Path(base) / "ha-presence"


def source_path(root: Path, source: str, state: str) -> Path:
    digest = hashlib.sha256(f"{source}\0{state}".encode()).hexdigest()
    return root / "sources" / f"{digest}.json"


def set_source(
    root: Path,
    source: str,
    state: str,
    active: bool,
    now: float | None = None,
    instance: str | None = None,
) -> None:
    if not source or len(source) > 512:
        raise ValueError("source must contain between 1 and 512 characters")
    if state not in STATES:
        raise ValueError(f"unknown presence state: {state}")

    instance = instance or os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    sources_directory = root / "sources"
    if instance:
        for existing_path in sources_directory.glob("*.json"):
            try:
                existing = json.loads(existing_path.read_text(encoding="utf-8"))
                existing_instance = existing.get("instance")
                if existing_instance and existing_instance != instance:
                    existing_path.unlink()
            except (OSError, ValueError, json.JSONDecodeError):
                continue

    path = source_path(root, source, state)
    if not active:
        try:
            path.unlink()
        except FileNotFoundError:
            pass
        return

    timestamp = time.time() if now is None else now
    try:
        existing = json.loads(path.read_text(encoding="utf-8"))
        if existing.get("source") == source and existing.get("state") == state:
            timestamp = float(existing["since"])
    except (FileNotFoundError, KeyError, TypeError, ValueError, json.JSONDecodeError):
        pass

    record = {"source": source, "state": state, "since": timestamp}
    if instance:
        record["instance"] = instance
    atomic_json(path, record)


def read_sources(root: Path, now: float | None = None) -> list[dict[str, Any]]:
    timestamp = time.time() if now is None else now
    records: list[dict[str, Any]] = []
    for path in sorted((root / "sources").glob("*.json")):
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
            source = str(record["source"])
            state = str(record["state"])
            since = min(float(record["since"]), timestamp)
            if source and state in STATES:
                records.append({"source": source, "state": state, "since": since})
        except (OSError, KeyError, TypeError, ValueError, json.JSONDecodeError):
            continue
    return records


class StateEngine:
    """Qualify raw facts, then stabilize the priority-selected state."""

    def __init__(
        self,
        priority: list[str],
        stability_seconds: float,
        gaming_seconds: float,
        restored: dict[str, Any] | None = None,
    ) -> None:
        self.priority = priority
        self.stability_seconds = stability_seconds
        self.gaming_seconds = gaming_seconds
        self.candidate: str | None = None
        self.candidate_since: float | None = None
        self.stable: str | None = None

        if restored:
            candidate = restored.get("candidate")
            stable = restored.get("stable")
            if candidate in (*STATES, "normal"):
                self.candidate = candidate
                try:
                    self.candidate_since = float(restored["candidate_since"])
                except (KeyError, TypeError, ValueError):
                    self.candidate_since = None
            if stable in (*STATES, "normal"):
                self.stable = stable

    def evaluate(self, records: list[dict[str, Any]], now: float) -> dict[str, Any]:
        raw = {state: False for state in STATES}
        gaming_since: float | None = None
        for record in records:
            state = record["state"]
            raw[state] = True
            if state == "gaming":
                since = float(record["since"])
                gaming_since = since if gaming_since is None else min(gaming_since, since)

        qualified = dict(raw)
        qualified["gaming"] = bool(
            gaming_since is not None and now - gaming_since >= self.gaming_seconds
        )
        selected = next((state for state in self.priority if qualified[state]), "normal")

        if selected != self.candidate:
            self.candidate = selected
            self.candidate_since = now
        elif self.candidate_since is None:
            self.candidate_since = now

        eligible_at = self.candidate_since + self.stability_seconds
        if now >= eligible_at:
            self.stable = self.candidate

        return {
            "raw": raw,
            "qualified": qualified,
            "gaming_since": gaming_since,
            "candidate": self.candidate,
            "candidate_since": self.candidate_since,
            "eligible_at": eligible_at,
            "stable": self.stable,
        }


class MqttConnection:
    def __init__(self, config: dict[str, Any]) -> None:
        self.config = config
        self.connected = threading.Event()
        self.needs_sync = threading.Event()
        self.last_error: str | None = None
        self.client = mqtt.Client(
            mqtt.CallbackAPIVersion.VERSION2,
            client_id=f"ha-presence-{config['device_id']}",
            protocol=mqtt.MQTTv311,
        )
        password = Path(config["password_file"]).read_text(encoding="utf-8").rstrip("\r\n")
        self.client.username_pw_set(config["username"], password)
        self.client.will_set(config["availability_topic"], "offline", qos=1, retain=True)
        self.client.reconnect_delay_set(min_delay=1, max_delay=30)
        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect

    def _on_connect(self, _client, _userdata, _flags, reason_code, _properties) -> None:
        if reason_code == 0:
            self.last_error = None
            self.connected.set()
            self.needs_sync.set()
        else:
            self.last_error = f"MQTT connection refused: {reason_code}"
            self.connected.clear()

    def _on_disconnect(self, _client, _userdata, _flags, reason_code, _properties) -> None:
        self.connected.clear()
        self.needs_sync.set()
        if reason_code != 0:
            self.last_error = f"MQTT disconnected: {reason_code}"

    def start(self) -> None:
        self.client.connect_async(self.config["host"], int(self.config.get("port", 1883)), 30)
        self.client.loop_start()

    def publish(self, topic: str, payload: str) -> bool:
        if not self.connected.is_set():
            return False
        try:
            info = self.client.publish(topic, payload, qos=1, retain=True)
            if info.rc != mqtt.MQTT_ERR_SUCCESS:
                self.last_error = f"MQTT publish rejected: {mqtt.error_string(info.rc)}"
                return False
            info.wait_for_publish(timeout=5)
            if not info.is_published():
                self.last_error = "MQTT publish acknowledgement timed out"
                return False
            self.last_error = None
            return True
        except (RuntimeError, ValueError, OSError) as error:
            self.last_error = f"MQTT publish failed: {error}"
            return False

    def stop(self) -> None:
        if self.connected.is_set():
            self.publish(self.config["availability_topic"], "offline")
        self.client.disconnect()
        self.client.loop_stop()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def deliver_stable(connection: Any, topic: str, stable: str | None, delivered: str | None) -> str | None:
    if stable is not None and stable != delivered and connection.publish(topic, stable):
        return stable
    return delivered


def daemon(config_path: Path, root: Path) -> int:
    config = load_json(config_path)
    status_path = root / "status.json"
    try:
        restored = load_json(status_path)
    except (OSError, ValueError, json.JSONDecodeError):
        restored = None

    engine = StateEngine(
        priority=list(config["priority"]),
        stability_seconds=float(config["stability_seconds"]),
        gaming_seconds=float(config["gaming_seconds"]),
        restored=restored,
    )
    connection = MqttConnection(config)
    stopping = threading.Event()
    signal.signal(signal.SIGTERM, lambda _signum, _frame: stopping.set())
    signal.signal(signal.SIGINT, lambda _signum, _frame: stopping.set())
    connection.start()
    delivered: str | None = None
    last_status: dict[str, Any] | None = None

    try:
        while not stopping.is_set():
            now = time.time()
            records = read_sources(root, now)
            result = engine.evaluate(records, now)

            if connection.needs_sync.is_set() and connection.connected.is_set():
                discovery_ok = connection.publish(config["config_topic"], config["discovery_payload"])
                state_ok = False
                availability_ok = False
                if discovery_ok and result["stable"] is not None:
                    state_ok = connection.publish(config["state_topic"], result["stable"])
                    if state_ok:
                        delivered = result["stable"]
                        # Make the entity available only after its retained state
                        # is current, avoiding a brief stale value on startup.
                        availability_ok = connection.publish(config["availability_topic"], "online")
                if discovery_ok and state_ok and availability_ok:
                    connection.needs_sync.clear()

            delivered = deliver_stable(connection, config["state_topic"], result["stable"], delivered)

            status = {
                **result,
                "sources": records,
                "mqtt_connected": connection.connected.is_set(),
                "mqtt_available": connection.connected.is_set() and not connection.needs_sync.is_set(),
                "delivered": delivered,
                "last_error": connection.last_error,
            }
            if status != last_status:
                atomic_json(status_path, {**status, "updated_at": now})
                last_status = status
            stopping.wait(0.25)
    finally:
        connection.stop()
    return 0


def parse_bool(value: str) -> bool:
    if value == "true":
        return True
    if value == "false":
        return False
    raise argparse.ArgumentTypeError("expected true or false")


def main() -> int:
    parser = argparse.ArgumentParser(prog="ha-presence")
    parser.add_argument("--runtime-dir")
    subparsers = parser.add_subparsers(dest="command", required=True)

    source_parser = subparsers.add_parser("source", help="set one raw presence fact")
    source_parser.add_argument("source")
    source_parser.add_argument("state", choices=STATES)
    source_parser.add_argument("active", type=parse_bool)

    subparsers.add_parser("status", help="print qualification and delivery status")
    daemon_parser = subparsers.add_parser("daemon")
    daemon_parser.add_argument("--config", required=True, type=Path)
    args = parser.parse_args()

    try:
        root = runtime_directory(args.runtime_dir)
        if args.command == "source":
            set_source(root, args.source, args.state, args.active)
            return 0
        if args.command == "status":
            print((root / "status.json").read_text(encoding="utf-8"), end="")
            return 0
        return daemon(args.config, root)
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as error:
        print(f"ha-presence: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
