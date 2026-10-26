# Build from source

Requires **Xcode 27 or later with Swift 6.4** and **macOS 14 or later**.

Open [Fluidtime.xcodeproj](../Fluidtime.xcodeproj), select the **Fluidtime** scheme and **My Mac**, then build and run. The app appears in your menu bar.

To package a built Release app as a DMG with an Applications shortcut and a SHA-256 checksum:

```sh
bash scripts/create-dmg.sh /path/to/Release/Fluidtime.app /private/tmp/fluidtime-release
```

For codebase conventions and development workflows, see [AGENTS.md](../AGENTS.md).

[Back to Fluidtime](../README.md)
