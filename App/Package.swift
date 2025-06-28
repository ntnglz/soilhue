// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SoilHue",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "SoilHue",
            targets: ["SoilHue"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jmcnamara/XlsxWriter", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "SoilHue",
            dependencies: ["XlsxWriter"]),
        .testTarget(
            name: "SoilHueTests",
            dependencies: ["SoilHue"]),
    ]
) 