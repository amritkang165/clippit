<!-- Purpose: Explain SQLite search behavior and how filters combine with queries. -->
# Search and filters

History search queries SQLite for a substring of the stored content. The query
is bound as a parameter; percent signs, underscores, and backslashes are escaped
so they search for literal characters instead of acting as LIKE wildcards.

The selected filter applies together with the query:

| Filter | Matching entries |
| --- | --- |
| All | Text and images |
| Text only | Entries without an image path |
| Images | Entries with an image path |
| Pinned | Pinned text or images |

Results default to newest first. The toolbar can instead show oldest first or
pinned first, with newest entries first within each pin group. Image records have the content label `Image`;
search does not recognize text inside images or search their pixels. If a clip
seems missing, clear the query and select All before investigating capture.

SQLite LIKE determines case matching; do not assume full Unicode case folding.
