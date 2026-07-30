import tempfile
import unittest
from pathlib import Path

from app import (
    JellyfinClient,
    JellyfinError,
    create_app,
    normalize_catalog,
)


class FakeJellyfin:
    def authenticate(self, username, password):
        if password != "correct":
            from app import JellyfinError

            raise JellyfinError("Jellyfin rejected the credentials")
        return {
            "AccessToken": "token",
            "User": {"Id": f"user-{username}", "Name": username},
        }

    def library_items(self, user_id, token):
        return SAMPLE_ITEMS

    def visible_item_ids(self, user_id, token):
        return {
            item["Id"]
            for item in SAMPLE_ITEMS
            if item["Type"] in {"Movie", "Series", "Season"}
        }

    def sync_items(self, page_size=250):
        return SAMPLE_ITEMS

    def image(self, item_id):
        return b"image", "image/jpeg"


SAMPLE_ITEMS = [
    {
        "Id": "series-1",
        "Type": "Series",
        "Name": "Northbound",
        "SortName": "Northbound",
        "ImageTags": {"Primary": "tag"},
    },
    {
        "Id": "season-1",
        "Type": "Season",
        "Name": "Season 1",
        "SeriesId": "series-1",
        "SeriesName": "Northbound",
    },
    {
        "Id": "episode-1",
        "Type": "Episode",
        "Name": "Arrival",
        "SeriesId": "series-1",
        "SeasonId": "season-1",
        "SeriesName": "Northbound",
        "SeasonName": "Season 1",
        "ParentIndexNumber": 1,
        "IndexNumber": 1,
        "MediaSources": [
            {
                "Size": 10_000_000_000,
                "RunTimeTicks": 36_000_000_000,
                "Bitrate": 22_000_000,
                "Path": "/media/Northbound/S01E01.mkv",
                "MediaStreams": [
                    {"Type": "Video", "Height": 2160, "Width": 3840, "Codec": "hevc"}
                ],
            }
        ],
    },
    {
        "Id": "movie-1",
        "Type": "Movie",
        "Name": "The Long Way",
        "ProductionYear": 2026,
        "MediaSources": [
            {
                "Size": 5_000_000_000,
                "RunTimeTicks": 72_000_000_000,
                "Path": "/media/movies/The Long Way.mkv",
                "MediaStreams": [
                    {"Type": "Video", "Height": 1080, "Width": 1920, "Codec": "h264"}
                ],
            }
        ],
    },
]


class CatalogTests(unittest.TestCase):
    def test_aggregates_episode_storage_at_season_and_series(self):
        catalog = normalize_catalog(SAMPLE_ITEMS)
        by_id = {item["id"]: item for item in catalog["items"]}
        self.assertEqual(by_id["season-1"]["sizeBytes"], 10_000_000_000)
        self.assertEqual(by_id["series-1"]["sizeBytes"], 10_000_000_000)
        self.assertEqual(by_id["series-1"]["height"], 2160)
        self.assertEqual(by_id["series-1"]["codecs"], ["HEVC"])
        self.assertEqual(catalog["files"][0]["path"], "/media/Northbound/S01E01.mkv")
        self.assertNotIn("episode-1", by_id)


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.app = create_app(
            {
                "TESTING": True,
                "DATABASE": str(Path(self.tempdir.name) / "votes.sqlite"),
                "SYNC_LOCK": str(Path(self.tempdir.name) / "sync.lock"),
                "SYNC_ON_START": True,
                "ADMIN_USERNAME": "juicy",
            },
            FakeJellyfin(),
        )

    def tearDown(self):
        self.tempdir.cleanup()

    def login(self, username="alex"):
        client = self.app.test_client()
        response = client.post(
            "/api/login", json={"username": username, "password": "correct"}
        )
        self.assertEqual(response.status_code, 200)
        return client, response.get_json()

    def test_login_vote_and_user_vote_round_trip(self):
        client, session = self.login()
        response = client.post(
            "/api/votes",
            json={"itemId": "movie-1", "choice": "archive"},
            headers={"X-CSRF-Token": session["csrf"]},
        )
        self.assertEqual(response.status_code, 200)
        catalog = client.get("/api/catalog").get_json()
        movie = next(item for item in catalog["items"] if item["id"] == "movie-1")
        self.assertEqual(movie["vote"], "archive")

    def test_only_juicy_can_read_shortlist(self):
        voter, _ = self.login()
        self.assertEqual(voter.get("/api/admin/shortlist").status_code, 403)
        admin, _ = self.login("juicy")
        self.assertEqual(admin.get("/api/admin/shortlist").status_code, 200)

    def test_dontcare_only_is_not_actionable(self):
        voter, session = self.login()
        voter.post(
            "/api/votes",
            json={"itemId": "movie-1", "choice": "dontcare"},
            headers={"X-CSRF-Token": session["csrf"]},
        )
        admin, _ = self.login("juicy")
        self.assertEqual(admin.get("/api/admin/shortlist").get_json()["items"], [])

    def test_admin_can_review_a_shortlist_item(self):
        voter, voter_session = self.login()
        voter.post(
            "/api/votes",
            json={"itemId": "movie-1", "choice": "delete"},
            headers={"X-CSRF-Token": voter_session["csrf"]},
        )
        admin, admin_session = self.login("juicy")
        self.assertEqual(len(admin.get("/api/admin/shortlist").get_json()["items"]), 1)
        response = admin.post(
            "/api/admin/reviews",
            json={"itemId": "movie-1", "status": "reviewed"},
            headers={"X-CSRF-Token": admin_session["csrf"]},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(admin.get("/api/admin/shortlist").get_json()["items"], [])

    def test_forever_and_delete_votes_become_an_admin_conflict(self):
        keeper, keeper_session = self.login("keeper")
        keeper.post(
            "/api/votes",
            json={"itemId": "movie-1", "choice": "archive"},
            headers={"X-CSRF-Token": keeper_session["csrf"]},
        )
        deleter, deleter_session = self.login("deleter")
        deleter.post(
            "/api/votes",
            json={"itemId": "movie-1", "choice": "delete"},
            headers={"X-CSRF-Token": deleter_session["csrf"]},
        )
        admin, _ = self.login("juicy")
        shortlist = admin.get("/api/admin/shortlist").get_json()["items"]
        self.assertEqual(shortlist[0]["recommendation"], "conflict")
        self.assertEqual(shortlist[0]["counts"]["archive"], 1)
        self.assertEqual(shortlist[0]["counts"]["delete"], 1)

    def test_non_admin_cannot_start_catalog_sync(self):
        voter, session = self.login()
        response = voter.post(
            "/api/admin/sync",
            headers={"X-CSRF-Token": session["csrf"]},
        )
        self.assertEqual(response.status_code, 403)


class PagingClient(JellyfinClient):
    def __init__(self):
        super().__init__("http://jellyfin.invalid")
        self.starts = []

    def request(self, method, path, **kwargs):
        start = int(kwargs["query"]["StartIndex"])
        limit = int(kwargs["query"]["Limit"])
        self.starts.append(start)
        total = 625
        end = min(start + limit, total)
        return {
            "Items": [
                {"Id": f"item-{index}", "Type": "Episode"}
                for index in range(start, end)
            ],
            "StartIndex": start,
            "TotalRecordCount": total,
        }


class SyncTests(unittest.TestCase):
    def test_paged_items_uses_total_record_count(self):
        client = PagingClient()
        items = client.paged_items(
            item_types="Episode",
            fields="MediaSources",
            page_size=250,
        )
        self.assertEqual(len(items), 625)
        self.assertEqual(client.starts, [0, 250, 500])

    def test_failed_sync_keeps_previous_catalog(self):
        class FailingJellyfin(FakeJellyfin):
            def sync_items(self, page_size=250):
                raise JellyfinError("service key rejected")

        with tempfile.TemporaryDirectory() as tempdir:
            app = create_app(
                {
                    "TESTING": True,
                    "DATABASE": str(Path(tempdir) / "votes.sqlite"),
                    "SYNC_LOCK": str(Path(tempdir) / "sync.lock"),
                },
                FailingJellyfin(),
            )
            store = app.extensions["media_vote_store"]
            store.replace_catalog(normalize_catalog(SAMPLE_ITEMS), 1)
            previous_success = store.sync_status()["succeededAt"]
            with self.assertRaises(JellyfinError):
                app.extensions["media_vote_sync"].run()
            self.assertEqual(len(store.catalog()["items"]), 3)
            self.assertEqual(store.sync_status()["status"], "error")
            self.assertEqual(
                store.sync_status()["succeededAt"],
                previous_success,
            )


if __name__ == "__main__":
    unittest.main()
