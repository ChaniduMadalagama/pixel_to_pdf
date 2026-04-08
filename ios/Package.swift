// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "pixel_to_pdf",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(name: "pixel_to_pdf", targets: ["pixel_to_pdf"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "pixel_to_pdf",
            dependencies: [],
            path: "Classes"
        )
    ]
)
