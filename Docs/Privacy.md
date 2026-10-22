<!-- Purpose: Explain local data storage and the limits of capture filtering. -->
# Local data and privacy

ClipVault stores text, timestamps, pin state, and image paths in
`~/Library/Application Support/ClipVault/clips.sqlite3`. Captured images are
stored alongside it as `clip-<UUID>.png`. Preferences are stored in macOS
UserDefaults. The app has no clipboard upload or cloud-sync feature.

These files are not encrypted by ClipVault. System backups or other software
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
