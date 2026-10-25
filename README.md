<!-- Purpose: Explain ClipVault, local development, storage, and licensing. -->
# ClipVault

A native Swift and SwiftUI clipboard history app for macOS 14 and later.

ClipVault lives in the menu bar and supports searchable text and image history,
pinned clips, filters, a global Command-Shift-V shortcut, and optional launch at
login. Clipboard history is stored locally using SQLite and image files.

Capture can be paused from the menu, and oversized text copies can be skipped
using an optional character limit. History supports oldest/newest/pinned-first
sorting, non-destructive text copy transformations, clear-unpinned, and export
of the current text results as JSON.

## Guides

- [Controls and retention](Docs/Usage.md)
- [Local storage and privacy](Docs/Privacy.md)
- [Search and filters](Docs/Search.md)
- [Retention and pins](Docs/Retention.md)
- [Reporting problems](Docs/Support.md)
- [Manual verification](Docs/ManualTesting.md)
- [Signing and release packaging](Distribution/ReleaseGuide.md)
- [Capture troubleshooting](Docs/Troubleshooting.md)
- [Copy and Paste](Docs/CopyAndPaste.md)
- [Launch at login](Docs/LoginItems.md)
- [Image history](Docs/Images.md)
- [Development workflow](Docs/Development.md)
- [Source architecture](Docs/Architecture.md)
- [Release checklist](Distribution/ReleaseChecklist.md)
- [Release notes template](Distribution/ReleaseNotesTemplate.md)

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

This project was imported into this repository on November 5, 2026. At the
owner's request, seven initial commits were assigned October 21, 2026 dates,
five documentation commits were assigned October 22, 2026 dates, and eleven
documentation and release-preparation commits were assigned October 23, 2026
dates. Four further documentation commits were assigned October 24, 2026 dates.
These assigned dates do not represent when the commits were actually created.

The October 25, 2026 batch contains 25 implementation, test, and documentation
commits added retrospectively. It replaces an earlier batch of empty markers;
these dates do not indicate when the features were actually implemented.
