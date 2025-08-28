// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AICamera-iOS",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AICamera-iOS",
            targets: ["AICamera-iOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager", from: "1.16.0")
    ],
    targets: [
        .target(
            name: "AICamera-iOS",
            dependencies: [
                .product(name: "onnxruntime_objc", package: "onnxruntime-swift-package-manager")
            ]),
    ]
)
