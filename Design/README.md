<!-- Purpose: Describe the Clippit visual redesign and its runnable source package. -->

Clippit visual redesign

Open `Clippit.xcodeproj` and run the Clippit scheme on My Mac. The current project includes this redesign; the original Steps/Step1–Step10 snapshots are kept separately where available.

The history window now uses adaptive pale-neutral and charcoal surfaces, a teal accent, readable clip cards, filter counts, and a selected-clip preview. Text can be selected within the preview. Images are downsampled for a larger preview without changing the original stored file. Copy, Copy & Paste, Pin, and Delete are available alongside the preview. The newest matching clip is selected when there is no current valid selection.

Native toolbar search, the global shortcut, SQLite search, clipboard capture, and local storage remain in place. At widths of 940 points and above, a library sidebar contains the four filters and counts. Smaller windows use a compact horizontal filter strip. Clip cards are denser, the preview has a clearer type header, and image text recognition has a dedicated panel. Settings and the empty state use the same visual theme. The history window starts at 1040 × 700 points and can shrink to 760 × 520.

`Previews/` contains renders of the real SwiftUI views using temporary sample clips, not the user's clipboard history. Window renders include the native title bar and search field. Both light and dark appearances were inspected, along with the compact layout and empty state.

Build verification: `swift build`. Regression checks: `python3 Checks/run.py`. Interactive keyboard, menu, and paste behavior should also be checked in the running Xcode-built app. Packaging instructions remain in `Distribution/ReleaseGuide.md`.

For this visual update, the SwiftPM build and the existing search/filter, shortcut,
and native search-focus checks passed. The known Vision runtime problem in issue
#12 is separate and was not addressed by the layout changes.
