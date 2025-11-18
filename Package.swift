// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-testing-performance",
    products: [
        .library(
            name: "TestingPerformance",
            targets: ["TestingPerformance"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/coenttb/swift-memory-allocation", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "TestingPerformance",
            dependencies: [
                .product(name: "MemoryAllocation", package: "swift-memory-allocation")
            ]
        ),
        .testTarget(
            name: "TestingPerformance Tests",
            dependencies: ["TestingPerformance"]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
