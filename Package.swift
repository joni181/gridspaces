// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "GridSpaces",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GridSpacesCore", targets: ["GridSpacesCore"]),
        .library(name: "GridSpacesOverlayKit", targets: ["GridSpacesOverlayKit"]),
        .executable(name: "gridspaces", targets: ["gridspaces"]),
        .executable(name: "GridSpacesAgent", targets: ["GridSpacesAgent"]),
        .executable(name: "GridSpacesOverlayAgent", targets: ["GridSpacesOverlayAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/dduan/TOMLDecoder.git", exact: "0.4.4"),
    ],
    targets: [
        .target(
            name: "GridSpacesCore",
            dependencies: [.product(name: "TOMLDecoder", package: "TOMLDecoder")]
        ),
        .executableTarget(
            name: "gridspaces",
            dependencies: ["GridSpacesCore"]
        ),
        .target(
            name: "GridSpacesOverlayKit",
            dependencies: ["GridSpacesCore"]
        ),
        .executableTarget(
            name: "GridSpacesAgent",
            dependencies: ["GridSpacesCore"]
        ),
        .executableTarget(
            name: "GridSpacesOverlayAgent",
            dependencies: ["GridSpacesCore", "GridSpacesOverlayKit"]
        ),
        .testTarget(
            name: "GridSpacesCoreTests",
            dependencies: ["GridSpacesCore"]
        ),
        .testTarget(
            name: "GridSpacesAgentTests",
            dependencies: ["GridSpacesAgent", "GridSpacesOverlayKit"]
        ),
    ]
)
