<!-- Purpose: Provide a repeatable manual check of native app behavior. -->
# Manual verification

Use disposable sample content in a development instance. These checks are a
checklist, not a record that they have passed on every supported Mac.

- Launch the app, copy `ClipVault sample A`, wait a second, and find it in history.
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
