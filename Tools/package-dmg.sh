#!/bin/bash
# Purpose: Package an exported, notarized ClipVault.app into a signed drag-to-Applications DMG.
set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo 'Usage: bash Tools/package-dmg.sh /path/to/ClipVault.app /path/to/ClipVault-1.0.dmg "Developer ID Application: Your Name (TEAMID)"' >&2
    exit 2
fi
clipvault_app="$1"
clipvault_output="$2"
clipvault_identity="$3"
clipvault_root="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$clipvault_app/Contents" ] || { echo 'An exported .app bundle is required.' >&2; exit 1; }
[ ! -e "$clipvault_output" ] || { echo 'Output already exists. Choose a new DMG filename.' >&2; exit 1; }
command -v create-dmg >/dev/null || { echo 'Install the packaging tool with: brew install create-dmg' >&2; exit 1; }
codesign --verify --deep --strict "$clipvault_app"
clipvault_signature="$(codesign -d --verbose=4 "$clipvault_app" 2>&1)"
printf '%s\n' "$clipvault_signature" | grep -q 'Authority=Developer ID Application:' || {
    echo 'Export with Developer ID Application signing before packaging.' >&2; exit 1;
}
printf '%s\n' "$clipvault_signature" | grep -q 'flags=.*runtime' || {
    echo 'The exported app must enable Hardened Runtime.' >&2; exit 1;
}
xcrun stapler validate "$clipvault_app"
mkdir -p "$(dirname "$clipvault_output")"
clipvault_output="$(cd "$(dirname "$clipvault_output")" && pwd)/$(basename "$clipvault_output")"
clipvault_stage="$(mktemp -d "${TMPDIR:-/tmp}/clipvault-dmg.XXXXXX")"
trap 'rm -rf "$clipvault_stage"' EXIT
ditto "$clipvault_app" "$clipvault_stage/ClipVault.app"
create-dmg \
    --volname "ClipVault" \
    --volicon "$clipvault_root/Artwork/ClipVault.icns" \
    --window-pos 200 120 \
    --window-size 640 420 \
    --icon-size 96 \
    --text-size 14 \
    --icon "ClipVault.app" 180 190 \
    --hide-extension "ClipVault.app" \
    --app-drop-link 460 190 \
    "$clipvault_output" "$clipvault_stage"
codesign --force --sign "$clipvault_identity" --timestamp "$clipvault_output"
codesign --verify --strict "$clipvault_output"
printf 'Created signed DMG: %s\nNext: notarize and staple this DMG as described in Distribution/ReleaseGuide.md.\n' "$clipvault_output"
