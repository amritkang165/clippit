<!-- Purpose: Explain ClipVault, local development, storage, and licensing. -->
# ClipVault

A native Swift and SwiftUI clipboard history app for macOS 14 and later.

ClipVault lives in the menu bar and supports searchable text and image history,
pinned clips, filters, a global Command-Shift-V shortcut, and optional launch at
login. Clipboard history is stored locally using SQLite and image files.

## Development

Open `ClipVault.xcodeproj` in Xcode and run the ClipVault scheme on My Mac.
Swift Package Manager resolves SQLite.swift and HotKey automatically.

For command-line compilation and regression checks:

```sh
swift build
python3 Checks/run.py
```

Interactive clipboard, hotkey, and paste behavior should also be tested in the
running app. Copy and Paste requires macOS Accessibility permission.

## Storage

History is saved under `~/Library/Application Support/ClipVault/`, with text
and metadata in `clips.sqlite3` and images in separate files. Preferences use
UserDefaults. There is no clipboard cloud sync or upload. Stored history is
not encrypted by the app. Password-source filtering is best effort.

## Distribution

See [the release guide](Distribution/ReleaseGuide.md) for signing, notarization,
and DMG packaging. This repository does not itself provide a notarized release.

## License

ClipVault is proprietary software, free to use under the
[ClipVault Software License](LICENSE). It is not open source. Redistribution,
resale, and modification require permission, subject to the license terms.
Dependencies retain their [own licenses](ClipVault/ThirdPartyNotices.txt).

## Repository history

This project was imported into this repository on November 5, 2026. Its seven
initial commits were assigned October 21, 2026 dates at the owner's request;
those dates do not represent when the commits were actually created.
