<!-- Purpose: Describe everyday Clippit controls and retention behavior. -->
# Using Clippit

Launch the app and use the clipboard icon in the menu bar to open history.
Copy something after launching: existing clipboard contents are not imported
at startup. While running, Clippit checks for changes every half second.

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
timestamps, content, and pin state, with formatVersion 1. Images and image paths
are excluded. The save panel lets you choose the destination or cancel.

Exports are unencrypted and are not a complete image-history backup. Clippit
does not currently import them. Deleting history does not delete prior exports.
