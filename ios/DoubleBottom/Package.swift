// swift-tools-version: 6.1
// Платформа: iOS 27.1 / Xcode 27.1 (iPhone Duo)

import PackageDescription

let package = Package(
    name: "DoubleBottom",
    defaultLocalization: "ru",
    platforms: [
        .iOS("27.1"),
        .macOS(.v15) // Для запуска BalanceSimulator и юнит-тестов из CLI
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Rules", targets: ["Rules"]),
        .library(name: "DuoDisplay", targets: ["DuoDisplay"]),
        .library(name: "DuoHinge", targets: ["DuoHinge"]),
        .library(name: "Tell", targets: ["Tell"]),
        .executable(name: "BalanceSimulatorCLI", targets: ["BalanceSimulatorCLI"])
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [],
            path: "Sources/Core"
        ),
        .target(
            name: "Rules",
            dependencies: ["Core"],
            path: "Sources/Rules",
            resources: [
                .process("Resources/DeckData.json"),
                .process("Resources/CaptainLines.json")
            ]
        ),
        // SecretState изолирован в модуле DuoSecret, недоступном для OuterScene
        .target(
            name: "DuoSecret",
            dependencies: ["Core", "Rules"],
            path: "Sources/Duo/Secret"
        ),
        .target(
            name: "DuoHinge",
            dependencies: ["Core"],
            path: "Sources/Duo/Hinge"
        ),
        .target(
            name: "DuoDisplay",
            dependencies: ["Core", "Rules", "DuoHinge"],
            path: "Sources/Duo/Display"
        ),
        .target(
            name: "Tell",
            dependencies: ["Core"],
            path: "Sources/Tell"
        ),
        .executableTarget(
            name: "BalanceSimulatorCLI",
            dependencies: ["Core", "Rules"],
            path: "Sources/BalanceSimulatorCLI"
        ),
        .testTarget(
            name: "DoubleBottomTests",
            dependencies: ["Core", "Rules", "DuoSecret", "DuoHinge", "DuoDisplay", "Tell"],
            path: "Tests/DoubleBottomTests"
        )
    ]
)
