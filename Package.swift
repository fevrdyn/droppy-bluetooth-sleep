// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Bluetoothsleep",
    platforms: [.macOS(.v14)],
    products: [
        // A droplet is a loadable bundle, so its product is a dynamic library.
        // Do not make it static: the app already carries DroppyKit, and a
        // second copy inside the droplet gives the same type two metadata
        // records, which fails every cast between them.
        .library(name: "Bluetoothsleep", type: .dynamic, targets: ["Bluetoothsleep"])
    ],
    dependencies: [
        .package(url: "https://gitlab.com/droppyformac1/droppykit.git", from: "1.20.1")
    ],
    targets: [
        .target(
            name: "Bluetoothsleep",
            dependencies: [.product(name: "DroppyKit", package: "droppykit")]
        ),
        .executableTarget(
            name: "BluetoothsleepHarness",
            dependencies: [
                "Bluetoothsleep",
                .product(name: "DroppyKitHarness", package: "droppykit")
            ]
        )
    ]
)
