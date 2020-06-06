// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "TaskUIKit",
  platforms: [
    .iOS(.v11),
  ],
  products: [
    .library(name: "TaskUIKit", targets: ["TaskUIKit"]),
    .library(name: "TaskUIKitJSON", targets: ["TaskUIKitJSON"]),
  ],
  dependencies: [
    .package(url: "https://github.com/sereivoanyong/SwiftKit", .branch("master")),
    .package(url: "https://github.com/sereivoanyong/DZNEmptyDataSet", .branch("master")),
    .package(url: "https://github.com/sereivoanyong/MJRefresh", .branch("master")),
    .package(url: "https://github.com/ra1028/DiffableDataSources", from: "0.4.0"),
    .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: "5.0.0"),
  ],
  targets: [
    .target(name: "TaskUIKit", dependencies: ["SwiftKit", "DiffableDataSources", "DZNEmptyDataSet", "MJRefresh"]),
    .target(name: "TaskUIKitJSON", dependencies: ["TaskUIKit", "SwiftyJSON"]),
  ],
  swiftLanguageVersions: [.v5]
)
