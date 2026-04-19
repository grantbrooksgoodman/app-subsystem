// swift-tools-version: 6.0

/* Native */
import PackageDescription

// MARK: - Package

let package = Package(
    name: "AppSubsystem",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
    ],
    products: [
        .library(
            name: "AppSubsystem",
            targets: ["AppSubsystem"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/grantbrooksgoodman/alert-kit", branch: "swift-6"),
        .package(url: "https://github.com/grantbrooksgoodman/component-kit", branch: "swift-6"),
        .package(url: "https://github.com/grantbrooksgoodman/translator", branch: "swift-6"),
//        .package(url: "https://github.com/nicklockwood/SwiftFormat", branch: "main"),
//        .package(url: "https://github.com/realm/SwiftLint", branch: "main"),
    ],
    targets: [
        .target(
            name: "AppSubsystem",
            dependencies: [
                .product(name: "AlertKit", package: "alert-kit", moduleAliases: nil),
                .product(name: "ComponentKit", package: "component-kit", moduleAliases: nil),
                .product(name: "Translator", package: "translator", moduleAliases: nil),
            ],
            path: "Sources",
            swiftSettings: [.swiftLanguageMode(.v6)],
            plugins: [ /* .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint") */ ]
        ),
    ]
)
