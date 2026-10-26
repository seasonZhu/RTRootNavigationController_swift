# RTRootNavigationController_Swift

使用 Swift 重建的 UIKit 导航框架。每个内容页面拥有独立导航栏，由外层根导航器统一管理真实导航栈；包含内建交互式 Push。

iOS 13+，Swift 5.9+，无第三方运行依赖。重建版本元数据为 1.0.0，尚未发布。

## 集成

SPM：在 Xcode 中添加本地仓库目录，选择 `RTRootNavigationController_Swift` 产品。正式发布标签后，可使用仓库地址添加远程包。

CocoaPods：

```ruby
platform :ios, '13.0'
use_frameworks!
pod 'RTRootNavigationController_Swift', :path => '/本地/RTRootNavigationController_Swift'
```

远程 Git 集成需先将本次源码推送到对应分支或标签，本轮未执行推送或发布。

## 使用

```swift
import UIKit
import RTRootNavigationController_Swift

let root = RTRootNavigationController(rootViewController: HomeController())
window.rootViewController = root

// 页面导航器会把操作转发至根导航器。
navigationController?.pushViewController(DetailController(), animated: true)

// 获取内容页面，而非内部包装器。
let pages = rt.navigationController?.rt.viewControllers
rt.navigationController?.popToRootViewController(animated: true) { finished in
    print("导航完成：\(finished)")
}
```

`root.viewControllers/topViewController/visibleViewController` 保留 UIKit 包装栈语义，真实页面请使用 `root.rt.viewControllers/topViewController/visibleViewController`。页面导航器的 `viewControllers` 返回真实栈。

### 命名空间

通过 `page.rt.navigationController` 获取根导航器，通过 `root.rt.viewControllers`、`root.rt.topViewController` 和 `root.rt.visibleViewController` 获取真实内容页面。设置 `page.rt.isInteractivePopDisabled = true` 可显式禁用交互返回。

采用与 Kingfisher、RxSwift 类似的泛型包装器：`RTNavigation<Base>` 保留控制器类型，仅 `UIViewController` 及其子类提供 `.rt` 入口。定制协议成员直接使用无前缀名称，仍由业务页面实现。旧 `rt_` API 已移除，调用方需要同步迁移；UIKit 原生导航方法和已有完成回调重载保持原调用方式。

### 页面定制

```swift
final class DetailController: UIViewController, RTNavigationCustomizing {
    var navigationBarClass: UINavigationBar.Type? { MyNavigationBar.self }

    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem? {
        UIBarButtonItem(title: "返回", style: .plain, target: target, action: action)
    }

    func nextSiblingController() -> UIViewController? {
        DetailController()
    }
}
```

协议还有 `animatedTransitioning`，用于提供页面转场动画；动画如需交互控制器，可遵循 `RTViewControllerAnimatedTransitioning`。外部 `UINavigationControllerDelegate` 优先于页面动画；内建交互 Push 手势进行时使用框架自身的交互动画。

默认从右边缘向左拖动触发交互 Push，RTL 方向反转。页面不提供下一页时不会开始；通过 `isInteractivePushEnabled` 关闭。超过一半进度或向前速度超过 500 点/秒时完成，快速反向拖动时取消。

### 返回与外观

- `rt.isInteractivePopDisabled` 显式设置后优先；未设置时，隐藏导航栏或使用业务左按钮会禁用边缘返回，框架生成的左按钮不触发禁用。
- `onBackCallback` 只接管框架生成的返回按钮，设置后不会自动 pop。使用 `[weak self]` 捕获页面，避免循环引用。系统返回按钮、侧滑、程序化 pop 不经过回调。
- `useSystemBackBarButtonItem` 建议在入栈前设置；系统返回使用前一页面标题与 backBarButtonItem。
- 默认每页外观独立；在页面自己的 `navigationItem` 或 `navigationController.navigationBar` 上设置。显式设置 `transferNavigationBarAttributes = true` 后继承根导航器和根页面外观。
- 完成回调在非动画或无操作时立即返回 `true`；动画取消返回 `false`，后续带完成回调的操作替换前一个待完成回调时，前者返回 `false`。若该回调重入发起更新的操作，被替换的外层操作停止执行。

TabBar 可分别嵌套根导航器，或用 `RTRootNavigationController(rootViewControllerNoWrapping:)` 包裹包含 `RTContainerNavigationController` 的 TabBar。Storyboard 可将导航器类设为本模块的 `RTRootNavigationController`；演示包含 unwind 资源。

## 演示与验证

- SPM：打开 `Example/SPM/Demo.xcodeproj`，选择 `DemoSPM`。
- CocoaPods：运行 `pod install --project-directory=Example/CocoaPods`，打开其 `Demo.xcworkspace`，选择 `DemoCocoaPods`。
- 两套工程共用 `Example/Shared` 的纯 Swift 场景；工程已纳入版本控制，无需生成工具即可打开。
- `scripts/generate_examples.rb` 使用 Ruby `xcodeproj` 重新生成工程，仅在调整工程结构时使用；之后重新执行 `pod install`。
- `bash scripts/verify.sh` 执行判定测试及两种方式的测试编译，不启动模拟器。

功能覆盖与验证边界见 [功能对照表](docs/FEATURE_PARITY.md) 和 [验证记录](docs/VALIDATION.md)。旧 Swift 接口不保证源码兼容，定制方法迁移至上述协议。

## 授权

MIT。保留原 Objective-C 框架与旧 Swift 仓库的版权声明，见 LICENSE。
