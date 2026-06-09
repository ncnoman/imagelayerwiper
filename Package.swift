// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ImageLayerWiper",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ImageLayerWiper",
            path: "Sources"
        )
    ]
)
