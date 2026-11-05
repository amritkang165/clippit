<!-- Purpose: Provide a repeatable manual check of native app behavior. -->
# Manual verification

Use disposable sample content in a development instance. These checks are a
checklist, not a record that they have passed on every supported Mac.

- Launch the app, copy `Clippit sample A`, wait a second, and find it in history.
- Copy the same text again immediately; confirm no consecutive duplicate appears.
- Copy a second sample, quit, and relaunch; confirm both stored entries remain.
- Search for part of a sample, then clear the query and try every filter.
- Copy a small image; confirm its thumbnail, detail preview, and paste into an
  image-capable app. Try text again afterward.
- Pin a sample, lower the retention limit, and confirm pinned content survives.
  Restore the desired limit afterward.
- Select a row and use Return and Command-C; paste into a scratch document.
- With a scratch app as the previous active app, test Command-Shift-C after
  granting Accessibility permission. Confirm the intended app receives it.
- From another app, press Command-Shift-V twice with a query present; confirm
  the history opens and the existing search text is selected each time.
- Edit text in search; confirm Delete edits the query instead of deleting a clip.
- Delete an expendable image and verify its history entry disappears.
- Test Clear all's Cancel path first. Test confirmation only with disposable
  history; it includes pinned items.
- Check light/dark appearances and resize the history window to its minimum.
- For an installed release, opt into launch at login and verify after logging
  out and back in. Disable it afterward if unwanted.

Run `python3 Checks/run.py` for automated checks using temporary stores,
private pasteboards, and a fake login service. Those checks do not replace
real hotkey, Accessibility, login, and downloaded-release testing.

## Capture and history tools

- Pause Capture from the menu, copy dummy text and an image, and confirm neither
  appears. Resume and confirm the paused clipboard is not imported. Copy fresh
  text and confirm capture resumes. Repeat pause after relaunch to check persistence.
- Set Maximum text characters to 3. Copy a four-character sample and confirm it
  stays on the system clipboard but is not recorded. Copy three characters and
  confirm capture. Restore 0 for unlimited capture. Test invalid input as well.
- Right-click a text clip and exercise each Copy as transformation; paste into
  a scratch editor and verify the original stored text remains unchanged.
- Switch each sort mode while searching and filtering. Pin an older clip and
  confirm Pinned first brings it ahead of unpinned clips.
- Test Clear unpinned's Cancel path, then confirm with disposable text and image
  entries. Verify pinned text and images remain available and copy correctly.
- Export a filtered set with text and images. Cancel once, then save to a
  temporary local folder. Verify the JSON contains only the matching text with
  pin metadata and no image paths. Delete the temporary export when finished.

These are manual acceptance steps, not a claim they have all been executed.

## Image text recognition

- Copy a screenshot containing clear text. Select it, click Recognize Text,
  and verify the progress indicator, readable result, and Copy Text button.
- Paste the result into a scratch editor and confirm plain text is copied.
  The original Copy action should still restore the image.
- Try an image without text and verify the no-text message; try a missing or
  corrupted saved image and verify a recoverable error.
- Start recognition, then select another clip or close history. Confirm no
  previous image's text appears in the newly selected clip.
- Check the image preview and recognized-text area at minimum window size and
  in both light and dark appearances. Select and copy a portion of the result.
- Verify recognition with networking disabled. Results are temporary and do not
  become search results or text exports unless separately saved as text.
