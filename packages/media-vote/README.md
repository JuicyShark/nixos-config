# Media Vote

A private companion site for a Jellyfin library. Jellyfin accounts authenticate
users; votes are stored separately in SQLite. The application never deletes,
moves, or replaces media.

Voting stops at movies, series, and seasons:

- **Forever** protects a title as a permanent keep.
- **Delete** proposes it for admin review.
- **Better** proposes a higher-quality replacement.
- **Don't care** records an abstention without adding admin noise.

The Jellyfin user configured as the administrator gets a ranked shortlist,
catalog-sync controls, and a large-file diagnostic table. Jellyfin login tokens
are held in memory, so an application restart signs everyone out.

Catalog metadata is fetched with a server-side Jellyfin API key in pages and
committed atomically to SQLite. User login tokens are only used for lightweight
library-visibility checks; slow or failed syncs leave the last good catalog
available.

## Local development

```console
MEDIA_VOTE_DATABASE=/tmp/media-vote.sqlite \
MEDIA_VOTE_JELLYFIN_URL=http://jellyfin.home.arpa \
MEDIA_VOTE_JELLYFIN_API_KEY_FILE=/run/secrets/jellyfin-api \
flask --app app run --port 8787
```

Populate or refresh the catalog before browsing:

```console
python app.py sync
```

Run tests from this directory:

```console
python -m unittest discover -s tests
```
