<!-- Purpose: Explain paste targeting, permissions, and recoverable errors. -->
# Copy and Paste

Open the destination app and focus its editable field before opening Clippit.
Select a history row and invoke Copy and Paste. Clippit remembers the previous
regular app and attempts to send it Command-V after activation and key release.

| Result | Recovery |
| --- | --- |
| Accessibility permission requested | Allow Clippit in the system Accessibility settings, then retry |
| No destination available | Open the destination app, then reopen history |
| Activation failed or shortcut keys remained held | Release the keys and paste manually with Command-V |
| Clipboard changed before paste | Select the desired clip and retry |

Copying and pasting are separate actions: the clip may already be on the
clipboard even when simulated paste fails. Copy alone remains available.
An app receiving Command-V still decides whether its focused field can paste.

History shows a brief Copied confirmation only after a successful clipboard
write, including Copy as and OCR Copy Text. VoiceOver receives an announcement.
The confirmation does not move focus or use animation, and repeated copies
restart its duration. It confirms copying only, never delivery to another app.
Failed copies clear any previous success confirmation and report their error.
