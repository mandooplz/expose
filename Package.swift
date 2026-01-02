// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Expose",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(
            name: "Expose",
            targets: ["Expose"]
        ),
        .executable(
            name: "ExposeClient",
            targets: ["ExposeClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0-latest"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", branch: "main"),
        .package(url: "https://github.com/CombineCommunity/RxCombine.git", branch: "main")
    ],
    targets: [
        .target(
            name: "Expose",
            dependencies: [
                "ExposeMacros",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "RxCombine", package: "RxCombine")
            ]
        ),
        .macro(
            name: "ExposeMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .executableTarget(
            name: "ExposeClient",
            dependencies: [
                "Expose"
            ]
        ),

        // A test target used to develop the macro implementation.
        .testTarget(
            name: "ExposeTests",
            dependencies: [
                "ExposeMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
