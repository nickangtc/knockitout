// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KnockItOut",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "KnockItOut", targets: ["KnockItOut"])
    ],
    targets: [
        .executableTarget(
            name: "KnockItOut",
            path: "Sources/KnockItOut",
            linkerSettings: [.linkedFramework("Carbon")]
        )
    ]
)
