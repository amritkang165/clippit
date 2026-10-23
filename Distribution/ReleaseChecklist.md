<!-- Purpose: Track release readiness without implying checks have passed. -->
# Release checklist

Complete this for each release; unchecked boxes are not verification claims.

- [ ] Set the final bundle identifier, team, version, and build number.
- [ ] Run automated checks and the manual verification checklist.
- [ ] Archive and export with Developer ID Application signing.
- [ ] Verify advertised architectures, hardened runtime, and entitlements.
- [ ] Obtain accepted app notarization and validate its stapled ticket.
- [ ] Package the DMG, notarize it, and validate its staple and signature.
- [ ] Compute the checksum after all modifications to the DMG are complete.
- [ ] Include the proprietary terms and dependency notices with distribution.
- [ ] Test a downloaded installation and launch on a clean user account.
- [ ] Publish only release artifacts to the intended download host.
- [ ] Record the actual download URL, version, and checksum.

Follow [ReleaseGuide.md](ReleaseGuide.md) for commands. No checkbox here is
completed automatically by building the source project.
