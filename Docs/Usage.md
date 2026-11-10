<!-- Purpose: Describe everyday Clippit controls and retention behavior. -->
# Using Clippit

Launch the app and use the clipboard icon in the menu bar to open history.
Copy something after launching: existing clipboard contents are not imported
at startup. While running, Clippit checks for changes every half second.

## Finding and reusing clips

Search matches stored text and snippet names. Use All, Text only, Images, Pinned, or Snippets to narrow the
list. Image contents are not searched with OCR. Select a clip to inspect its
full text or image preview.

| Control | Action |
| --- | --- |
| Command-Shift-V (default; configurable in Settings) | Open history and select the search query |
| Return on a selected row | Copy the clip and keep history open |
| Command-C on a selected row | Copy the clip |
| Command-Shift-C on a selected row | Copy and paste into the previous app |
| Delete on a selected row | Delete the clip from history |
| Pin button | Protect a clip from automatic retention cleanup |

Text fields retain normal text-editing shortcuts. Copy and Paste needs
Accessibility permission; copying alone does not use simulated keystrokes.
The menu also offers the ten newest clips for quick copying.

## Your history shortcut

In Settings → Open history, choose Record shortcut and press a letter, number,
Space or F1–F12 with Command or Control (Option and Shift can also be included).
Escape cancels. Keys are stored by physical key position; the displayed key
names use the US keyboard layout. Reset to default restores Command-Shift-V.
The binding survives restarts and the menu/library hints update immediately.
When macOS refuses a binding, the previous shortcut remains active. Some
system-reserved shortcuts cannot be detected reliably; choose another if one
does not fire. Opening history does not require Accessibility permission.

## Named snippets

Choose New snippet in the toolbar, or Save as snippet from a text clip's detail
view or context menu. Give it a name and text; whitespace-only fields are not
accepted. Unicode and line breaks are kept. Saving a clip as a snippet leaves
the original history entry unchanged. Use Snippets to find and edit saved
text, or search by name or content. Copy uses the same clipboard path as
history and does not capture a second history entry.

Snippets are local, do not count toward the history limit, and survive both
Clear history actions. Delete a snippet explicitly and confirm to remove it.
There is no automatic text expansion or cloud sync.

## Retention

Settings defaults to 500 items. Pinned clips survive automatic cleanup and can
cause the total to exceed the configured limit. Apply a changed limit to save
it. Clear all requires confirmation and removes pinned clips too, but does not
clear the current system clipboard. The footer counts retained clips from
today; deleting one reduces that count.

## Capture controls

Pause Capture in the menu stops new text and image capture while keeping saved
clips available. Resume Capture starts with future changes; it does not import
copies made while paused. The pause setting survives app restarts and can also
be changed in Settings.

Settings also offers Maximum text characters. Zero means unlimited. A copy
longer than the limit is skipped entirely without changing the system clipboard.
The limit counts user-perceived characters, including composed emoji, and does
not limit images or erase existing history.

## Sorting, transforming, and clearing

The history toolbar offers Newest first, Oldest first, and Pinned first sorting.
Sorting combines with the active search and filter; it does not change the ten
newest clips shown in the menu. Sort selection lasts for the current window.

Right-click a text clip and choose Copy as to trim whitespace, collapse it to a
single line, or change its case. The original history entry stays unchanged.
These transformations are not offered for images.

Clear unpinned in the menu removes unpinned history and its owned image files
after confirmation. Pins remain. Clear all still removes pins too.

## Export

Use Export visible text in the toolbar to save JSON containing the text entries
from the current search and filter, in their displayed order. It includes IDs,
timestamps, content, and pin state. Exports containing snippets use formatVersion
2 and include their snippetTitle; history-only exports retain formatVersion 1. Images and image paths
are excluded. The save panel lets you choose the destination or cancel.

Exports are unencrypted and are not a complete image-history backup. Clippit
does not currently import them. Deleting history does not delete prior exports.
