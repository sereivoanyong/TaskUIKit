// swift-tools-version:5.10

import PackageDescription

let package = Package(
  name: "TaskUIKit",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v13),
  ],
  products: [
    .library(name: "TaskUIKit", targets: ["TaskUIKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/CoderMJLee/MJRefresh", .upToNextMajor(from: "3.7.9")),
    .package(url: "https://github.com/sereivoanyong/EmptyUIKit", branch: "main"),
    .package(url: "https://github.com/sereivoanyong/SwiftKit", branch: "main")
  ],
  targets: [
    .target(name: "TaskUIKit", dependencies: [
      "MJRefresh",
      "EmptyUIKit",
      .product(name: "UIKitUtilities", package: "SwiftKit")
    ]),
  ]
)
