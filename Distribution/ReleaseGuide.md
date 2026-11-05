<!-- Purpose: Provide the exact Archive, Developer ID export, notarization, DMG, and sharing workflow for Clippit. -->

Clippit release walkthrough — macOS 14+

Run the commands below from the project folder. This guide uses version `1.0`, build `1`, and `Distribution/Export/Clippit.app`. Replace the example team, certificate identity, and version with yours. The Step 10 source ZIP is a development project; it is not a signed installer.

1. **Install and select full Xcode.** Open Xcode once to finish component installation and accept its license. The Command Line Tools alone can run this project's Swift checks, but cannot Archive or compile its asset catalog. Select Xcode for release commands:

   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   xcodebuild -version
   ```

2. **Set your signing identity.** In Xcode → Settings → Accounts, add the Apple Account associated with your Apple Developer Program membership. In Manage Certificates, ensure the team has an Apple Development certificate for archiving and a **Developer ID Application** certificate for distribution. Developer ID Installer is for installer packages, not this app/DMG. Certificate creation may require your team's Account Holder. See [Apple's Developer ID guidance](https://developer.apple.com/developer-id/).

   Open `Clippit.xcodeproj` and select the Clippit target. Under Signing & Capabilities, select your team and use automatic signing for Release. Choose your own stable reverse-DNS bundle identifier, for example `com.yourcompany.Clippit`, before the first public release. Debug currently uses local ad-hoc signing so development can run without a team; Release is configured for Apple Development and needs your team. If switching Debug to automatic signing too, remove its explicit `-` Code Signing Identity override in Build Settings.

   Hardened Runtime is already enabled. App Sandbox is off for this direct-distribution clipboard utility. Keep the macOS deployment target at 14.0. The supplied app-icon catalog and third-party notices are included as resources. In General, set Version to `1.0` and Build to `1`; increment these for subsequent releases.

3. **Check the app before archiving.** Select the shared Clippit scheme, choose My Mac, and run. Copy text and an image; check history, filters, pins, Return/⌘C, Delete, and the recent-clips menu. From another app, press ⌘⇧V twice with an existing query and confirm that the text is selected each time. Check Cancel and Clear All on disposable clips. Allow Accessibility when testing ⌘⇧C, then return to the intended destination app before retrying.

   The automated suite uses temporary databases, private pasteboards, and a fake login service:

   ```bash
   python3 Checks/run.py
   ```

   The footer counts **retained** clips from the current local calendar day, independently of search/filter. Removing clips reduces that count. SQLite files and image files stay in `~/Library/Application Support/ClipVault/`.

4. **Archive.** Choose Product → Scheme → Edit Scheme → Archive and confirm Build Configuration is Release. Choose the generic **Any Mac** destination if offered by your Xcode version, then Product → Archive. The Release target has Only Build Active Architecture set to No. Wait for the archive to appear in Window → Organizer → Archives. This is the app archive, not the executable produced by `swift build`.

5. **Export a notarization-ready app.** Select that archive → Distribute App → **Custom → Developer ID → Export**. Older Xcode versions show Developer ID directly. Select automatic signing and your team, review that the export uses **Developer ID Application**, then export into `Distribution/Export/`. Confirm that the result is `Distribution/Export/Clippit.app`. Export signs the app but does not notarize it. These choices follow [Apple's distribution flow](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases).

   You can instead choose **Direct Distribution** to have Xcode submit the app for notarization. After it is accepted, export the notarized app into the same folder and skip the app-submission commands in step 7; still validate its staple. Apple's [Organizer notarization instructions](https://help.apple.com/xcode/mac/current/en.lproj/dev88332a81e.html) explain the status and export controls.

   Check the exported binary and signature:

   ```bash
   lipo -archs "Distribution/Export/Clippit.app/Contents/MacOS/Clippit"
   codesign --verify --deep --strict --verbose=2 "Distribution/Export/Clippit.app"
   codesign -d --verbose=4 "Distribution/Export/Clippit.app"
   codesign -d --entitlements :- "Distribution/Export/Clippit.app"
   ```

   To support both Apple silicon and Intel, the architecture list must contain `arm64` and `x86_64`. Confirm a Developer ID Application authority, your TeamIdentifier, and the runtime signing flag. The exported release must not have `com.apple.security.get-task-allow` enabled. Fix signing/export settings and re-export if these checks disagree; do not replace the exported app's signature with an ad-hoc signature.

6. **Store notarization credentials locally.** Run this once and follow the Terminal prompts for your Apple ID, Team ID, and an app-specific password. Credentials are stored in Keychain, not in the repository:

   ```bash
   xcrun notarytool store-credentials "Clippit-notary"
   ```

7. **Notarize and staple the exported app.** For the Developer ID → Export route, run:

   ```bash
   ditto -c -k --sequesterRsrc --keepParent \
     "Distribution/Export/Clippit.app" "Distribution/Clippit-1.0-notary.zip"
   xcrun notarytool submit "Distribution/Clippit-1.0-notary.zip" \
     --keychain-profile "Clippit-notary" --wait
   ```

   Continue only when the submission says **Accepted**. Save its submission ID. If rejected, fetch the log, fix the issue, and rebuild/export:

   ```bash
   xcrun notarytool log "SUBMISSION-ID" \
     --keychain-profile "Clippit-notary" "Distribution/notary-log.json"
   ```

   Attach the ticket to the `.app`, not to the ZIP, and validate:

   ```bash
   xcrun stapler staple "Distribution/Export/Clippit.app"
   xcrun stapler validate "Distribution/Export/Clippit.app"
   spctl --assess --type execute --verbose=4 "Distribution/Export/Clippit.app"
   ```

   Apple's [custom notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow) documents submission, logs, and stapling. Do not edit the app bundle after signing/notarization.

8. **Create the DMG.** Install the shell tool [create-dmg](https://github.com/create-dmg/create-dmg) through Homebrew, then list your available certificate identities:

   ```bash
   brew install create-dmg
   security find-identity -v -p codesigning
   ```

   Copy the complete Developer ID Application identity into the following command, retaining the quotes:

   ```bash
   bash Tools/package-dmg.sh \
     "Distribution/Export/Clippit.app" \
     "Distribution/Clippit-1.0.dmg" \
     "Developer ID Application: Your Name (TEAMID)"
   ```

   The script validates the app's signature and staple, creates an isolated staging folder, invokes `create-dmg` with the Clippit volume icon and an Applications drop link, then signs the DMG. It refuses to overwrite an existing output. It may prompt for Terminal's Automation access to Finder because `create-dmg` uses Finder to arrange the window. Give a rebuilt DMG a new output name or move the previous output first. The script does not upload or publish anything.

9. **Notarize the final DMG and verify it.** The app inside is already stapled; now submit the exact disk image you will distribute:

   ```bash
   xcrun notarytool submit "Distribution/Clippit-1.0.dmg" \
     --keychain-profile "Clippit-notary" --wait
   ```

   After **Accepted**:

   ```bash
   xcrun stapler staple "Distribution/Clippit-1.0.dmg"
   xcrun stapler validate "Distribution/Clippit-1.0.dmg"
   codesign --verify --strict --verbose=2 "Distribution/Clippit-1.0.dmg"
   spctl --assess --type open --context context:primary-signature \
     --verbose=4 "Distribution/Clippit-1.0.dmg"
   shasum -a 256 "Distribution/Clippit-1.0.dmg" \
     > "Distribution/Clippit-1.0.dmg.sha256"
   ```

   Do not modify the DMG after this point. Open it, drag Clippit to Applications, eject it, and open the installed app. Enable Settings → Launch at login there, follow any Login Items approval request, and verify it after a logout/login. Disable it afterward if you do not want it enabled. Registering the stable installed copy avoids depending on an Xcode build folder or mounted DMG.

10. **Publish the download.** Upload only the final `Clippit-1.0.dmg` and optional SHA-256 file as release assets on your chosen HTTPS host, such as a GitHub Release. For GitHub: repository → Releases → Draft a new release → create a `v1.0` tag → attach those two files → publish. Copy the DMG asset's actual download link after publishing; do not substitute a source-code ZIP. A typical asset URL is `https://github.com/OWNER/REPO/releases/download/v1.0/Clippit-1.0.dmg`, but use the URL created for your repository. Download through that link on a clean Mac/user account and test Gatekeeper, installation, hotkey, clipboard permissions, and login behavior before announcing it. No release has been uploaded by this project.

To regenerate the editable icon artwork, run `swift Tools/GenerateIcon.swift`, then `iconutil -c icns .build/Clippit.iconset -o Artwork/Clippit.icns` before making a new archive.

## Public source and release downloads

The source repository `amritkang165/clippit` is public and MIT-licensed. Publish
finished binaries as GitHub Release assets here or on an approved HTTPS host.
Upload the final notarized DMG and its checksum as download assets; never upload
clipboard data. GitHub source archives are development source, not installers.

A future Homebrew cask should reference the publicly downloadable release
asset and its final SHA-256 checksum. No cask or public download is currently
published by this project. Keep the MIT license and third-party
notices available with the distributed product.
