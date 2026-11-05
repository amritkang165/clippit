<!-- Purpose: Explain how contributors can claim work, validate changes, and submit focused pull requests. -->
# Contributing to ClipVault

ClipVault is MIT-licensed. The repository is currently private while public
release preparation is underway; these instructions also apply to collaborators
with access now. Public contributors will be able to fork it once it is public.

## Pick an issue

Browse the GitHub issues and choose a task that is not assigned or already
covered by an active pull request. Comment that you want to work on it and
briefly describe your approach. This helps avoid duplicate work. Issues labeled
`good first issue` have a narrower scope; priority labels indicate urgency, not
an obligation to work on them. Leave unrelated features for separate issues.

## Set up

Use a Mac running macOS 14 or later. Open `ClipVault.xcodeproj` in Xcode and run
the ClipVault scheme on My Mac. Dependencies resolve through Swift Package
Manager. Command-line builds and checks are also available:

```sh
swift build
python3 Checks/run.py
```

The checks create temporary databases, private pasteboards, and generated OCR
images. They do not require your real clipboard history or signing credentials.
Vision recognition is tested locally and may use its CPU fallback.

## Make a change

Create a descriptive branch from current main. Keep the change focused and put
a purpose comment at the top of each new source file. Preserve macOS 14 support,
local clipboard storage, and password-filter behavior. Avoid adding telemetry
or network services without discussing the behavior first.

Add meaningful regression coverage for behavioral fixes. Run the checks, then
exercise affected UI actions using disposable sample content. Record checks
that were not possible, especially Accessibility paste, login registration,
minimum-OS behavior, and notarized installation. See Docs/ManualTesting.md.

## Submit a pull request

Link the issue, describe the behavior before and after, and report actual test
results. Include non-sensitive screenshots for UI changes when useful. Do not
commit generated builds, databases, signing keys, or personal clipboard data.
Use commit messages that describe actual changes, with normal current dates;
do not add empty commits to inflate activity. Existing retrospectively assigned
history is documented in README.md and is not a contribution convention.

Contributions should be submitted under the project's MIT license. Preserve
copyright notices and dependency licenses. A maintainer will review scope,
compatibility, and verification before merging.
