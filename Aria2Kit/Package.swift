// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Aria2Kit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Aria2Kit",
            targets: ["Aria2Kit"]
        ),
    ],
    targets: [
        .target(
            name: "Aria2Kit",
            dependencies: ["Aria2Core"]
        ),
        .target(
            name: "Aria2Core",
            dependencies: ["Aria2Binary"],
            path: "Sources/Aria2Core",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedLibrary("xml2"),
                .linkedLibrary("z"),
                .linkedLibrary("sqlite3"),
                .linkedFramework("Security"),
                .linkedFramework("Foundation")
            ]
        ),
        .binaryTarget(
            name: "Aria2Binary",
            path: "artifacts/Aria2.xcframework"
        ),
        .executableTarget(
            name: "builder",
            dependencies: [],
            path: "Sources/builder"
        )
    ],
    cxxLanguageStandard: .cxx14
)
