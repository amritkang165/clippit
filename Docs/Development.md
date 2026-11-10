<!-- Purpose: Explain the supported local development and validation paths. -->
# Development workflow

Use macOS 14 or later. Open the shared Clippit scheme in Xcode for interactive
app development. Package.swift also supports command-line compilation:

```sh
swift build
python3 Checks/run.py
```

The check runner builds the app, compiles a standalone checks executable, and
runs it with isolated fixtures. It covers storage, images, search, keyboard
classification, native search focus, menu behavior, and login-service state.

Full Xcode is required for the documented Archive/export workflow. A successful
SwiftPM build is not a signed or notarized app release. Consult the manual
verification checklist for real hotkey, paste, and login behavior.

Keep generated output under ignored build/export directories. Do not commit
signing credentials, user databases, or personal clipboard screenshots.

See [macOS CI](CI.md) for workflow configuration, Xcode source-list validation,
unit tests and separate core/OCR check suites.
