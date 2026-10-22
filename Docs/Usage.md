<!-- Purpose: Describe everyday ClipVault controls and retention behavior. -->
# Using ClipVault

Launch the app and use the clipboard icon in the menu bar to open history.
Copy something after launching: existing clipboard contents are not imported
at startup. While running, ClipVault checks for changes every half second.

## Finding and reusing clips

Search matches stored text. Use All, Text only, Images, or Pinned to narrow the
list. Image contents are not searched with OCR. Select a clip to inspect its
full text or image preview.

| Control | Action |
| --- | --- |
| Command-Shift-V | Open history and select the search query |
| Return on a selected row | Copy the clip and keep history open |
| Command-C on a selected row | Copy the clip |
| Command-Shift-C on a selected row | Copy and paste into the previous app |
| Delete on a selected row | Delete the clip from history |
| Pin button | Protect a clip from automatic retention cleanup |

Text fields retain normal text-editing shortcuts. Copy and Paste needs
Accessibility permission; copying alone does not use simulated keystrokes.
The menu also offers the ten newest clips for quick copying.

## Retention

Settings defaults to 500 items. Pinned clips survive automatic cleanup and can
cause the total to exceed the configured limit. Apply a changed limit to save
it. Clear all requires confirmation and removes pinned clips too, but does not
clear the current system clipboard. The footer counts retained clips from
today; deleting one reduces that count.
