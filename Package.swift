// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "FluidtimeCore",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FluidtimeCore", targets: ["FluidtimeCore"])],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.26.2"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "3.1.0"),
        .package(url: "https://github.com/orchetect/MenuBarExtraAccess", exact: "1.3.1"),
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .target(
            name: "FluidtimeCore",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
                .product(name: "MenuBarExtraAccess", package: "MenuBarExtraAccess"),
                .product(name: "Sparkle", package: "Sparkle")
            ], path: "Fluidtime",
            exclude: ["App/FluidtimeApp.swift", "App/FluidtimeAppDelegate.swift", "Resources/Assets.xcassets"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .testTarget(
            name: "FluidtimeCoreTests",
            dependencies: ["FluidtimeCore"],
            path: "Tests"
        )
    ]
)
