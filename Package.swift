// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "GridSpaces",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GridSpacesCore", targets: ["GridSpacesCore"]),
        .executable(name: "gridspaces", targets: ["gridspaces"]),
        .executable(name: "GridSpacesAgent", targets: ["GridSpacesAgent"]),
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
        .executableTarget(
            name: "GridSpacesAgent",
            dependencies: ["GridSpacesCore"]
        ),
        .testTarget(
            name: "GridSpacesCoreTests",
            dependencies: ["GridSpacesCore"]
        ),
    ]
)
