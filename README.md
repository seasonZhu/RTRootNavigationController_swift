# RTRootNavigationController_Swift

一个基于 UIKit、纯 Swift 实现的导航容器。每个业务页面拥有独立导航栏，外层 `RTRootNavigationController` 管理导航栈与转场，页面仍可使用 UIKit 的 Push / Pop 调用方式。

要求 iOS 13+、Swift 5.9+、Xcode 15+，无第三方运行依赖。当前 Package 和 Podspec 版本元数据为 1.0.0；版本元数据不代表已发布同名 Git 标签或 CocoaPods 版本。

## 目录

- [集成](#集成)
- [基本调用与导航栈](#基本调用与导航栈)
- [页面导航栏与返回](#页面导航栏与返回)
- [交互手势与自定义转场](#交互手势与自定义转场)
- [常见业务场景](#常见业务场景)
- [API 速查](#api-速查)
- [演示与验证](#演示与验证)

## 集成

### Swift Package Manager

在 Xcode 的 **File → Add Package Dependencies** 输入：

```text
https://github.com/seasonZhu/RTRootNavigationController_Swift.git
```

选择 Branch 规则并填写 `main`，将 `RTRootNavigationController_Swift` 产品添加到应用 Target。分支依赖会随更新变化；需要固定源码时使用指定 Revision，发布版本标签后可改为版本规则。本地开发也可通过 Add Local 添加仓库目录。

已有 `Package.swift` 的项目可添加：

```swift
.package(
    url: "https://github.com/seasonZhu/RTRootNavigationController_Swift.git",
    branch: "main"
)
```

并在消费模块的 `dependencies` 中添加：

```swift
.product(
    name: "RTRootNavigationController_Swift",
    package: "RTRootNavigationController_Swift"
)
```

### CocoaPods

在应用的 Podfile 中配置实际 Target 名称：

```ruby
platform :ios, '13.0'
use_frameworks!

target 'YourApp' do
  pod 'RTRootNavigationController_Swift',
      :git => 'https://github.com/seasonZhu/RTRootNavigationController_Swift.git',
      :branch => 'main'
end
```

执行 `pod install`，之后打开 `.xcworkspace`。本地开发可将该依赖替换为：

```ruby
pod 'RTRootNavigationController_Swift', :path => '/本地/RTRootNavigationController_Swift'
```

同一个应用 Target 选择一种依赖方式即可。示例中的 `HomeController`、`DetailController` 等名称代表业务自行定义的控制器。

## 基本调用与导航栈

### 创建窗口根导航器

在 SceneDelegate 的窗口创建逻辑中配置：

```swift
import UIKit
import RTRootNavigationController_Swift

// windowScene 为当前连接的 UIWindowScene。
let window = UIWindow(windowScene: windowScene)
let navigation = RTRootNavigationController(rootViewController: HomeController())
window.rootViewController = navigation
self.window = window
window.makeKeyAndVisible()
```

未使用 Scene 生命周期的项目，在 AppDelegate 的窗口初始化处执行相同配置，改用 `UIWindow(frame: UIScreen.main.bounds)`。导航操作及页面定制应在主线程执行；框架命名空间和定制协议受 `@MainActor` 隔离。

### Push / Pop

在已加入框架的业务页面中，继续使用页面的 `navigationController`：

```swift
navigationController?.pushViewController(DetailController(), animated: true)
navigationController?.popViewController(animated: true)
navigationController?.popToRootViewController(animated: true)
```

页面实际获得的是 `RTContainerNavigationController`，它将导航操作转发给根导航器。不要将待 Push 的页面预先包进普通 `UINavigationController`，也不要重复 Push 同一个页面实例。

需要框架特有功能或完成回调时，通过 `.rt.navigationController` 取得根导航器：

```swift
rt.navigationController?.pushViewController(DetailController(), animated: true) { finished in
    print("转场完成：\(finished)")
}

rt.navigationController?.popViewController(animated: true) { finished in
    print("返回完成：\(finished)")
}
```

完成回调的 `true` 表示完成，`false` 表示取消或被后续带完成回调的操作替换。非动画和无操作时可能同步回调 `true`，不能将其当作“确实移除了页面”的凭据。只有一个待完成回调槽位；旧回调若重入发起新操作，被替换的外层操作会停止执行。返回方法的同步返回值表示尝试移除的页面，动画最终是否完成以回调为准。

### 读取真实页面栈

```swift
if let root = rt.navigationController {
    let pages = root.rt.viewControllers
    let top = root.rt.topViewController
    let visible = root.rt.visibleViewController
    print(pages, top as Any, visible as Any)
}
```

| 访问入口 | 语义 |
| --- | --- |
| `root.viewControllers` | UIKit 外层栈，元素通常是 `RTContainerController` 包装器 |
| `root.topViewController` | 外层栈顶包装器 |
| `root.visibleViewController` | UIKit 当前可见控制器，可能包含模态展示页面 |
| `root.rt.viewControllers` | 按顺序解包后的真实业务页面 |
| `root.rt.topViewController` | 解包后的真实栈顶页面 |
| `root.rt.visibleViewController` | 对 UIKit 可见控制器解包；可能是模态页面 |
| `page.navigationController?.viewControllers` | 挂接根导航器时返回完整的真实业务栈 |
| `page.rt.navigationController` | 查找外层 `RTRootNavigationController`，未挂接时为 `nil` |

`.rt` 采用泛型 `RTNavigation<Base>` 包装，`base` 保留原控制器具体类型。不要依赖包装器作为业务路由的标识。

### 定位、替换与移除页面

```swift
if let root = rt.navigationController,
   let home = root.rt.viewControllers.first {
    root.popToViewController(home, animated: true) { finished in
        print(finished)
    }
}

// 例如登录完成后替换整个业务栈。
rt.navigationController?.setViewControllers([HomeController()], animated: false)

// 移除中间页，避免用户再次返回该页。
if let root = rt.navigationController,
   let page = root.rt.viewControllers.first(where: { $0 is LoginController }) {
    root.removeViewController(page)
}
```

`setViewControllers` 不能包含重复页面实例。`removeViewController` 默认无动画，目标不存在或将移除最后一个页面时不执行。`popToViewController` 的目标必须是栈内已有页面或其包装器；目标不存在时返回 `nil`。

## 页面导航栏与返回

### 各页面独立设置外观

业务页面通过自己的导航栏和 `navigationItem` 配置：

```swift
final class DetailController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "详情"
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBlue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }
}
```

每个页面拥有自己的导航栏，修改详情页外观不会要求同步修改上一页。要隐藏当前页面导航栏，在页面生命周期中调用 `navigationController?.setNavigationBarHidden(true, animated: animated)`；外层根导航栏始终隐藏，调用根导航器的同名方法不产生显隐效果。

若需要统一外观，设置根导航器的 `navigationBar` 样式，并在页面入栈前启用 `transferNavigationBarAttributes = true`。框架在显示和布局阶段复制根导航栏属性，以及根页面 `navigationItem` 的外观配置，可能覆盖页面局部样式；不同系统版本只复制可用的属性。

### 定制导航栏类型和返回按钮

```swift
final class BrandNavigationBar: UINavigationBar {}

final class BrandDetailController: UIViewController, RTNavigationCustomizing {
    var navigationBarClass: UINavigationBar.Type? { BrandNavigationBar.self }

    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem? {
        UIBarButtonItem(title: "返回", style: .plain, target: target, action: action)
    }
}
```

定制协议提供默认实现，可以只实现需要的成员。导航栏类型在创建包装器时读取，应在入栈前确定。返回按钮应绑定框架传入的 `target/action`；返回 `nil` 则使用默认文字按钮。已有业务 `leftBarButtonItem` 时，框架不覆盖它，其点击逻辑由业务负责。

### 使用系统返回按钮

```swift
let home = HomeController()
home.navigationItem.backBarButtonItem = UIBarButtonItem(
    title: "首页", style: .plain, target: nil, action: nil
)
let root = RTRootNavigationController(rootViewController: home)
root.useSystemBackBarButtonItem = true
root.pushViewController(DetailController(), animated: false)
```

请在后续页面入栈前开启。框架通过内部占位页提供上一页面的标题和 `backBarButtonItem`。该选项不会主动重建已有页面容器，`onBackCallback` 也不接管系统返回按钮。

### 点击返回前进行业务确认

```swift
// 在业务页面中配置；此回调属于整个根导航器，应管理好安装与清理时机。
rt.navigationController?.onBackCallback = { [weak self] in
    guard let self else { return }
    let alert = UIAlertController(title: "放弃编辑？", message: nil, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "继续编辑", style: .cancel))
    alert.addAction(UIAlertAction(title: "放弃", style: .destructive) { [weak self] _ in
        self?.rt.navigationController?.popViewController(animated: true)
    })
    self.present(alert, animated: true)
}
```

回调设置后不会自动 Pop。业务结束拦截时将 `onBackCallback` 设回 `nil`。它只处理框架生成按钮，无法拦截程序化 Pop、系统返回按钮和侧滑；编辑保护场景还需显式禁用侧滑，并统一业务导航入口。

## 交互手势与自定义转场

### 交互返回

```swift
// 隐藏导航栏或使用自定义左按钮时，显式允许侧滑返回。
rt.isInteractivePopDisabled = false

// 编辑未保存等场景，显式禁止侧滑返回。
rt.isInteractivePopDisabled = true
```

未赋值时，属性读取为 `false`，框架仍会自动判断：根页面不能返回；隐藏导航栏或设置业务左按钮会禁用交互返回，框架生成的左按钮不触发禁用。显式赋值后，以该值为准，但不会绕过根页面或转场期间的限制。此设置不影响点击返回或直接调用 Pop，目前没有公开 API 清除显式设置、恢复自动判定。

### 交互 Push 下一页

```swift
final class ReaderController: UIViewController, RTNavigationCustomizing {
    func nextSiblingController() -> UIViewController? {
        ReaderController() // 实际项目按当前章节返回下一章；最后一章返回 nil。
    }
}
```

默认从右边缘向左拖动进入下一页，RTL 时反向。`nextSiblingController()` 在手势开始判定时调用，不能返回已在栈中的页面；应避免在此执行扣费、上报完成等不可撤销操作。转场进度超过 50% 且反向速度不超过 500 点/秒，或向前速度超过 500 点/秒时完成，否则取消。

可通过 `root.isInteractivePushEnabled = false` 关闭。内建交互 Push 使用框架滑动动画；普通按钮 Push 不会自动使用这个滑动动画。

### 页面动画与外部代理

业务页面实现 `RTNavigationCustomizing.animatedTransitioning`，返回遵循 `UIViewControllerAnimatedTransitioning` 的动画对象。Push 取目标页面的动画，Pop 取来源页面的动画。需要交互控制时，动画对象还可遵循 `RTViewControllerAnimatedTransitioning`，提供 `interactiveTransitioning`；业务需自行管理该交互控制器的开始、进度和结束。

```swift
final class TransitionPageController: UIViewController, RTNavigationCustomizing {
    // animator 为业务实现的 UIViewControllerAnimatedTransitioning 实例。
    var animator: UIViewControllerAnimatedTransitioning?
    var animatedTransitioning: UIViewControllerAnimatedTransitioning? { animator }
}
```

动画选择顺序：内建交互 Push → 外部导航代理返回的动画 → 页面动画 → UIKit 默认动画。交互控制器也优先使用内建 Push，其次是代理，最后是动画对象提供的交互控制器。

外部代理示例：

```swift
final class NavigationObserver: NSObject, UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        print("已显示业务页面：\(viewController)")
    }
}

// observer 应作为业务对象的强引用属性保存，delegate 只弱引用它。
let observer = NavigationObserver()
root.delegate = observer
```

框架内部持有 UIKit 代理职责，业务通过 `delegate` 接收已转发的回调。`willShow/didShow` 及动画选择回调中的页面会解包为真实内容页面；自定义动画仍应通过 UIKit 的 `transitionContext` 获取实际参与转场的控制器和视图。框架仅显式转发显示、动画、交互控制器和方向相关方法，不保证代理协议中的其他可选方法被转发。

## 常见业务场景

### 每个 Tab 独立导航栈

```swift
let home = RTRootNavigationController(rootViewController: HomeController())
home.tabBarItem = UITabBarItem(title: "首页", image: nil, tag: 0)
let profile = RTRootNavigationController(rootViewController: ProfileController())
profile.tabBarItem = UITabBarItem(title: "我的", image: nil, tag: 1)
let tabs = UITabBarController()
tabs.viewControllers = [home, profile]
window.rootViewController = tabs
```

适合各 Tab 独立返回历史。进入详情时如需隐藏底部栏，在 Push 前设置详情页的 `hidesBottomBarWhenPushed = true`。内容页面的 `tabBarController` 查询在隐藏底部栏或底部栏不透明等情况下可能返回 `nil`，不要将其作为唯一的业务状态来源。

### 整个 TabBar 共用外层导航栈

```swift
let tabs = UITabBarController()
tabs.viewControllers = [
    RTContainerNavigationController(rootViewController: HomeController()),
    RTContainerNavigationController(rootViewController: ProfileController())
]
let root = RTRootNavigationController(rootViewControllerNoWrapping: tabs)
window.rootViewController = root
```

适合从任意 Tab 进入覆盖整个 TabBar 的详情。根 TabBar 不再额外添加页面导航栏；内部 Tab 使用 `RTContainerNavigationController`，导航操作转发到同一个外层根栈。此结构不为各 Tab 分别维护完整业务导航历史。

### Storyboard 与 unwind

将 Storyboard 导航器的 Custom Class 设置为 `RTRootNavigationController`，Module 设置为 `RTRootNavigationController_Swift`，照常连接根页面。框架在 `awakeFromNib` 中转换页面栈。`RTContainerController` 由框架创建，不能在 Storyboard 中直接实例化。

页面容器将 unwind 子页面搜索转发给根导航器。可参考 `Example/Shared` 的 Storyboard 和 unwind 示例；业务 segue、目标 Action 和 restoration 配置仍需由应用维护。

### 状态栏、旋转与系统手势

业务页面覆写 UIKit 的 `preferredStatusBarStyle`、`prefersStatusBarHidden`、`supportedInterfaceOrientations` 等属性，容器将查询转发给当前内容页面。状态变化后按 UIKit 方式调用 `setNeedsStatusBarAppearanceUpdate()` 等更新方法。支持方向仍受应用 Target 与 Info.plist 限制。子类覆写容器生命周期方法时应调用 `super`，以保留包装、外观同步及手势配置。

### 模态展示

内容页面照常调用 `present`。若模态流程也需要独立页面导航栏，用新的 `RTRootNavigationController(rootViewController:)` 包装后展示；模态导航栈与原导航栈各自管理。模态关闭使用 `dismiss`，Pop 只作用于对应导航栈。

## API 速查

| 类型 / API | 用途与默认值 |
| --- | --- |
| `RTRootNavigationController(rootViewController:)` | 创建带页面独立导航栏的根栈 |
| `init(rootViewControllerNoWrapping:)` | 根页面不加内部导航栏，适合 TabBar 容器 |
| `init(navigationBarClass:toolbarClass:)` | 创建空根导航器；参数配置外层栏 |
| `init(coder:)` | 支持 Storyboard 加载根导航器 |
| `useSystemBackBarButtonItem` | 系统返回按钮模式，默认 `false` |
| `transferNavigationBarAttributes` | 复制根外观，默认 `false` |
| `onBackCallback` / `onBack(_:)` | 框架返回按钮处理，回调默认 `nil` |
| `isInteractivePushEnabled` | 边缘交互 Push，默认 `true` |
| `delegate` | 弱引用业务代理，仅转发受支持方法 |
| `pushViewController(_:animated:)` | 压入真实页面，自动包装 |
| `setViewControllers(_:animated:)` | 替换栈，禁止重复页面实例 |
| `popViewController(animated:)` | 返回被移除的真实页面或 `nil` |
| `popToViewController(_:animated:)` | 返回至已有页面，结果为移除页面数组或 `nil` |
| `popToRootViewController(animated:)` | 返回根页面，结果为移除页面数组或 `nil` |
| 上述 Push / 三种 Pop 的 `completion` 重载 | 根导航器提供；参数为转场完成状态 |
| `removeViewController(_:animated:)` | 移除指定页面，动画默认 `false`，保留至少一页 |
| `RTNavigationCustomizing` | 可选页面导航栏、返回按钮、动画和下一页定制 |
| `RTViewControllerAnimatedTransitioning` | 自定义动画附带交互控制器 |
| `RTNavigationCompatible` / `RTNavigation<Base>` | `.rt` 入口、`base` 及类型安全扩展 |
| `rt.isInteractivePopDisabled` | 显式控制侧滑返回策略 |
| `rt.navigationController` | 查找根导航器 |
| `root.rt.viewControllers/topViewController/visibleViewController` | 读取解包后的页面 |
| `RTContainerController` | 页面包装器；只读内容页及内部导航器引用 |
| `RTContainerNavigationController` | 独立页面导航栏与根导航操作转发 |

公开的 UIKit 生命周期、导航代理及手势代理实现主要供系统调用，业务通常只需配置属性和协议，无需直接调用代理方法。详细参数与行为见 `Sources` 中的文档注释。旧 `rt_` API 已移除；迁移时改用 `.rt` 命名空间和无前缀定制协议成员，旧版本不保证源码兼容。

## 演示与验证

- SPM：打开 `Example/SPM/Demo.xcodeproj`，选择 `DemoSPM`。
- CocoaPods：运行 `pod install --project-directory=Example/CocoaPods`，打开 `Example/CocoaPods/Demo.xcworkspace`，选择 `DemoCocoaPods`。
- 两套工程共用 `Example/Shared` 场景代码，演示工程已纳入版本控制。
- `scripts/generate_examples.rb` 使用 Ruby `xcodeproj` 重新生成工程，仅调整工程结构时使用；随后重新执行 `pod install`。
- 执行 `bash scripts/verify.sh`，运行交互完成判定测试、Podspec 检查、两种集成方式的 `build-for-testing` 及 Storyboard 资源检查。该脚本不启动模拟器，UIKit XCTest 仅编译，手势、外观和真实 UIKit 运行行为仍需运行验证。

功能覆盖与已有验证边界见 [功能对照表](docs/FEATURE_PARITY.md) 和 [验证记录](docs/VALIDATION.md)。

## 授权

MIT。保留原 Objective-C 框架与旧 Swift 仓库的版权声明，见 [LICENSE](LICENSE)。
