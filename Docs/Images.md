<!-- Purpose: Explain supported image representations and missing-file behavior. -->
# Image history

The monitor prefers usable PNG or TIFF data over text when both representations
are present. Images are normalized to PNG and saved as individual files in the
application-support directory; SQLite stores their paths.

Rows display small thumbnails and the detail view uses a downsampled preview.
Search matches stored text, not pixels. On-demand text recognition is available
in the selected image preview.

Restoring an image reads and validates its file before clearing the current
clipboard, then offers PNG and TIFF representations to receiving apps. If the
file was removed or corrupted, copying cannot reconstruct it from its thumbnail.
Copy the original image again to create a usable entry.

Deleting and pruning entries clean up app-owned image files. Avoid manually
renaming those files or moving only the database away from its image directory.

## Recognize text

Select an image and click Recognize Text below its preview. Apple Vision reads
it on this Mac; no image is uploaded and no API key is required. Recognition
runs off the UI thread. Results appear as selectable text with a Copy Text
button. The regular Copy button continues to copy the original image.

Blank images show a no-text message; unreadable files show an error. Scan Again
retries recognition. Changing the selected clip discards a pending result.
Recognition accuracy and language support depend on Vision and image quality;
review the text before using it, especially numbers and commands.

Recognized text is temporary preview state. It is not written to SQLite,
indexed by search, or included in text-history exports. Copy Text uses the
normal restoration path, so it does not create another history entry. The
saved image stays unchanged. Images are downsampled to at most 4096 pixels on
the longest edge for recognition, which can affect tiny text in large images.
