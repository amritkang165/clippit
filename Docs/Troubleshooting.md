<!-- Purpose: Diagnose missing history without exposing clipboard contents. -->
# Capture troubleshooting

1. Confirm Clippit is running by locating its menu bar icon.
2. Copy fresh dummy text after launch and wait at least one second. Startup
   does not import the existing clipboard contents.
3. Open history, clear the search query, and choose All.
4. Check whether Ignore passwords is filtering the source application. Test
   with harmless text from a regular text editor, not an actual password.
5. Confirm the history limit has not pruned an older unpinned entry.

Unsupported clipboard formats are skipped. PNG and TIFF are supported; a file
copied in Finder is not necessarily image data on the clipboard. If an error
appears, record its message without sharing private clipboard contents.
