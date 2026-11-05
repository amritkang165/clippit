#!/bin/bash
# Purpose: Package an exported, notarized Clippit.app into a signed drag-to-Applications DMG.
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo 'Usage: bash Tools/package-dmg.sh /path/to/Clippit.app /path/to/Clippit-1.0.dmg "Developer ID Application: Your Name (TEAMID)"' >&2
    exit 2
fi
clippit_app="$1"
clippit_output="$2"
clippit_identity="$3"
clippit_root="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$clippit_app/Contents" ] || { echo 'An exported .app bundle is required.' >&2; exit 1; }
[ ! -e "$clippit_output" ] || { echo 'Output already exists. Choose a new DMG filename.' >&2; exit 1; }
command -v create-dmg >/dev/null || { echo 'Install the packaging tool with: brew install create-dmg' >&2; exit 1; }
codesign --verify --deep --strict "$clippit_app"
clippit_signature="$(codesign -d --verbose=4 "$clippit_app" 2>&1)"
printf '%s\n' "$clippit_signature" | grep -q 'Authority=Developer ID Application:' || {
    echo 'Export with Developer ID Application signing before packaging.' >&2; exit 1;
}
printf '%s\n' "$clippit_signature" | grep -q 'flags=.*runtime' || {
    echo 'The exported app must enable Hardened Runtime.' >&2; exit 1;
}
xcrun stapler validate "$clippit_app"
mkdir -p "$(dirname "$clippit_output")"
clippit_output="$(cd "$(dirname "$clippit_output")" && pwd)/$(basename "$clippit_output")"
clippit_stage="$(mktemp -d "${TMPDIR:-/tmp}/clippit-dmg.XXXXXX")"
trap 'rm -rf "$clippit_stage"' EXIT
ditto "$clippit_app" "$clippit_stage/Clippit.app"
create-dmg \
    --volname "Clippit" \
    --volicon "$clippit_root/Artwork/Clippit.icns" \
    --window-pos 200 120 \
    --window-size 640 420 \
    --icon-size 96 \
    --text-size 14 \
    --icon "Clippit.app" 180 190 \
    --hide-extension "Clippit.app" \
    --app-drop-link 460 190 \
    "$clippit_output" "$clippit_stage"
codesign --force --sign "$clippit_identity" --timestamp "$clippit_output"
codesign --verify --strict "$clippit_output"
printf 'Created signed DMG: %s\nNext: notarize and staple this DMG as described in Distribution/ReleaseGuide.md.\n' "$clippit_output"
