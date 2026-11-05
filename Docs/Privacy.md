<!-- Purpose: Explain local data storage and the limits of capture filtering. -->
# Local data and privacy

Clippit stores text, timestamps, pin state, and image paths in
`~/Library/Application Support/ClipVault/clips.sqlite3`. Captured images are
stored alongside it as `clip-<UUID>.png`. Preferences are stored in macOS
UserDefaults. The app has no clipboard upload or cloud-sync feature.

These files are not encrypted by Clippit. System backups or other software
with access to this directory may copy them. Local storage does not mean that
all other software on the Mac is prevented from accessing the files.

## Password filtering

Ignore passwords is enabled by default. It checks known confidential clipboard
markers and available source-app information, with the foreground application
as a fallback heuristic. Some applications provide no reliable source marker,
and the foreground app can change before polling. This feature cannot promise
to exclude every password or other sensitive value.

## Removing data

Delete a selected clip to remove its stored record and associated owned image.
Clear all removes history, including pins, after confirmation. Neither action
clears the system clipboard or guarantees forensic erasure from disk or backups.
Quitting stops capture; removing the app alone does not delete its history.

When reporting a problem, share dummy sample text instead of your database,
clipboard images, or screenshots containing private history.

## Pausing and explicit exports

Pause Capture stops recording new clipboard changes and persists across app
restarts. Resume does not import content copied while paused. A maximum text
length can skip oversized copies, but does not replace password filtering.

The export action writes only the visible text results to a JSON file at a
location you choose. Exports include potentially sensitive text and are not
encrypted. A synced destination may upload the file through other software.
Exported files remain after clearing history and must be managed separately.

The original `ClipVault` storage folder and bundle identifier are retained after
the rename to Clippit so existing history and preferences remain available.
