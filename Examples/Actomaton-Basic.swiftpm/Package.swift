// swift-tools-version: 5.5

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "Actomaton-Basic",
    platforms: [
        .iOS("15.2")
    ],
    products: [
        .iOSApplication(
            name: "Actomaton-Basic",
            targets: ["AppModule"],
            bundleIdentifier: "com.inamiy.Actomaton-Basic",
            teamIdentifier: "UMBZ5WL247",
            displayVersion: "1.0",
            bundleVersion: "1",
            iconAssetName: "AppIcon",
            accentColorAssetName: "AccentColor",
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/inamiy/Actomaton", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .productItem(name: "ActomatonStore", package: "Actomaton", condition: nil)
            ],
            path: "."
        )
    ]

)