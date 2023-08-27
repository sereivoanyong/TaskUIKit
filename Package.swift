// swift-tools-version:5.8

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
    .package(url: "https://github.com/sereivoanyong/UIKitSwift", branch: "main"),
  ],
  targets: [
    .target(name: "TaskUIKit", dependencies: ["MJRefresh", .product(name: "UIKitExtra", package: "UIKitSwift")]),
  ]
)
