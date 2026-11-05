<!-- Purpose: Explain opt-in login registration and installation requirements. -->
# Launch at login

Use a signed Clippit.app installed in Applications. Open Settings and enable
Launch at login. Registration is opt-in; starting Clippit does not silently
register it.

If macOS requires approval, follow the login-items settings link and approve
the app. A requested registration can be awaiting approval rather than active.
Settings refreshes its status from the system instead of assuming success.

After enabling it, log out and back in to verify the installed copy launches.
Disable the setting when no longer wanted. The bare executable produced by
Swift Package Manager is not the installed app bundle needed for this feature.
