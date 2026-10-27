# Build from source

Requires **Xcode 27 or later with Swift 6.4** and **macOS 14 or later**.

Open [Fluidtime.xcodeproj](../Fluidtime.xcodeproj), select the **Fluidtime** scheme and **My Mac**, then build and run. The app appears in your menu bar.

For a standalone demo, select the **Fluidtime Alpha** scheme and **My Mac**. It builds
**Fluidtime Alpha.app** with the separate bundle identifier `cz.matee.fluidtime.alpha`.
The app uses the same fictional Alex Morgan account and 35-day history as the review
previews. Start, stop, edit, delete, organization switching, and earnings settings work
against in-memory clients. Changes reset when you quit.

Alpha never contacts Solidtime or accesses Keychain, Touch ID, or login-item registration.
Updates and browser links are disabled. CSV export still uses the native save dialog.
Global shortcuts start unassigned to avoid conflicts with the regular app; any assignments
are stored under Alpha's separate app identity. After disconnecting, reconnect with
`https://example.invalid` and any fictional API key. No real credentials are needed.

To compile it without launching:

```sh
xcodebuild -project Fluidtime.xcodeproj -scheme 'Fluidtime Alpha' \
  -configuration Alpha -destination 'platform=macOS' \
  -derivedDataPath /tmp/fluidtime-build CODE_SIGNING_ALLOWED=NO build
```

To package a built Release app as a DMG with an Applications shortcut and a SHA-256 checksum:

```sh
bash scripts/create-dmg.sh /path/to/Release/Fluidtime.app /private/tmp/fluidtime-release
```

For codebase conventions and development workflows, see [AGENTS.md](../AGENTS.md).

[Back to Fluidtime](../README.md)
