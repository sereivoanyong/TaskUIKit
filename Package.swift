// swift-tools-version:5.9

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
    .package(url: "https://github.com/CoderMJLee/MJRefresh", .upToNextMajor(from: "3.7.6")),
    .package(url: "https://github.com/sereivoanyong/SwiftKit", branch: "main"),
  ],
  targets: [
    .target(name: "TaskUIKit", dependencies: [
      "MJRefresh",
      .product(name: "UIKitUtilities", package: "SwiftKit")
    ]),
  ]
)
