<!-- Purpose: Explain supported image representations and missing-file behavior. -->
# Image history

The monitor prefers usable PNG or TIFF data over text when both representations
are present. Images are normalized to PNG and saved as individual files in the
application-support directory; SQLite stores their paths.

Rows display small thumbnails and the detail view uses a downsampled preview.
Search matches stored text, not pixels. There is no OCR feature.

Restoring an image reads and validates its file before clearing the current
clipboard, then offers PNG and TIFF representations to receiving apps. If the
file was removed or corrupted, copying cannot reconstruct it from its thumbnail.
Copy the original image again to create a usable entry.

Deleting and pruning entries clean up app-owned image files. Avoid manually
renaming those files or moving only the database away from its image directory.
