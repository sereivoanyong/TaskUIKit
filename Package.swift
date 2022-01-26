// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "TaskUIKit",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v11),
  ],
  products: [
    .library(name: "TaskUIKit", targets: ["TaskUIKit"]),
  ],
  dependencies: [
    .package(url: "https://github.com/CoderMJLee/MJRefresh", .upToNextMajor(from: "3.7.5")),
    .package(url: "https://github.com/sereivoanyong/SwiftUIKit", .branch("master")),
  ],
  targets: [
    .target(name: "TaskUIKit", dependencies: ["MJRefresh", .product(name: "UIKitExtra", package: "SwiftUIKit")]),
  ]
)
