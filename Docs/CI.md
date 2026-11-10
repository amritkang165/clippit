<!-- Purpose: Describe macOS automation and what still needs hands-on release testing. -->
# macOS checks

Pull requests and pushes to main run on GitHub's `macos-15` Apple Silicon image,
with Xcode 16.4 explicitly selected through `DEVELOPER_DIR`. The image's installed
versions are documented in the [runner manifest](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md).
Missing Xcode installations fail visibly rather than silently selecting a new version.

The workflow runs SwiftPM unit tests, native UI/private-pasteboard checks, real
Vision recognition and an unsigned Xcode application build. The check script
also compares app Swift source files with Xcode's Sources build phase. It uses
SwiftPM's native build system explicitly because its check linker needs that
system's module and object-file layout.

Core and OCR checks are separate steps so an OCR backend failure does not hide
the other results. Neither step allows failures or skips checks based on CI.
The OCR step uses generated text and blank images and exercises the CPU retry
path, invalid images and cancellation. Logs are retained for 14 days even on
failure. Workflow permissions are read-only; no signing secrets are required.

These checks do not prove real Accessibility paste into another app, login-item
registration, VoiceOver speech on a user's setup, minimum macOS 14 behavior,
real global-key conflicts, or signed/notarized installation. Those remain in
the manual release checklist. Hosted CI itself can only be verified after the
workflow is pushed and run on GitHub.

Locally: `swift test --build-system native`, then `python3 Checks/run.py`.
Use `--suite core` or `--suite ocr` for a specific subsystem; the default runs both.
