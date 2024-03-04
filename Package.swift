// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SHFilesPicker",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SHFilesPicker",
            targets: ["SHFilesPicker"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/guoyingtao/Mantis", exact: "2.19.0")
    ],
    targets: [
        .target(
            name: "SHFilesPicker",
            dependencies: [
                .product(name: "Mantis", package: "Mantis")
            ]
        )
    ]
)
