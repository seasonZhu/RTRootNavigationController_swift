# 功能对照表

基线为源仓库 `master@9d2927c` 与 `develop_custom_onBack@4f777cd`。后者不是对主分支的整体覆盖，只合入返回按钮回调能力。原库默认 Core 和可选 Push 能力统一纳入本框架。

“测试”列表示已有自动化用例；UIKit 用例当前仅编译通过，不能视为运行通过。演示实际交互均待人工验收。

| 源功能 | Swift 接口或实现 | 演示 / 测试 |
| --- | --- | --- |
| 每页独立导航栏、容器生命周期 | RTContainerController / RTContainerNavigationController | 普通页面；WrappingAndNavigationLookup |
| 内容导航器的栈操作转发 | navigationController 的 push/pop/set/popTo/root | InnerPushPopAndRealStack |
| 真实 top、visible、stack | rt.topViewController / rt.visibleViewController / rt.viewControllers | 普通页面；栈操作测试 |
| 栈替换、删除、指定页面返回 | setViewControllers / removeViewController / popToViewController | 栈替换、Push 后移除；SetRemoveAndPopToIdentity |
| push/pop/popTo/root 完成回调 | completion: (Bool) -> Void | 栈替换；NonanimatedCompletionsAndNoOp、CompletionRunsOnceAfterDidShow、三项回调重入/取消用例 |
| 自定义导航栏类 | RTNavigationCustomizing.navigationBarClass | 自定义导航栏；CustomNavigationAndBackItem |
| 自定义返回按钮 | RTNavigationCustomizing.customBackItem | 自定义返回；CustomNavigationAndBackItem |
| 系统返回按钮及前页标题 | useSystemBackBarButtonItem | 系统返回；SystemBackPlaceholderAndButtonExclusion、ChangingStackRefreshesSystemBackTitle |
| 显式导航栏样式继承 | transferNavigationBarAttributes | 外观继承；AppearanceIsIndependentByDefaultAndInheritedExplicitly |
| 禁用交互返回及自动推断 | rt.isInteractivePopDisabled、手势代理 | 禁用返回、隐藏栏；ExplicitPopPreferenceOverridesHiddenBarDefault |
| 返回按钮回调接管 | onBackCallback / onBack | 返回接管；BackCallbackOnlyHandlesButtonAction |
| 自定义动画和交互控制器 | RTNavigationCustomizing、RTViewControllerAnimatedTransitioning | 自定义转场；CustomAnimationAndInteractionForwarding |
| 外部导航代理 | delegate，收到解包后的内容页面 | DelegateReceivesContentControllers |
| 交互式 Push、下一页提供 | nextSiblingController、isInteractivePushEnabled | 交互 Push、隐藏栏；InteractionCompletionThresholds |
| 交互转场完成和取消 | RTSlideAnimator、UIPercentDrivenInteractiveTransition | 交互 Push；SlideAnimatorCompletesAndCancels；独立判定测试 |
| 根页面不包装导航器 | init(rootViewControllerNoWrapping:) | 根导航包裹 TabBar；NoWrappingTabStructure |
| 两种 TabBar 组合、底栏隐藏转发 | 容器 tabBarController、hidesBottomBarWhenPushed | 两个 TabBar 入口与 Push 下一页 |
| Storyboard 初始化、show、unwind | required init(coder:)、awakeFromNib、UIKit 容器遍历 | UnwindFixture.storyboard；资源编译 |
| 旋转、状态栏、Home indicator、系统边缘手势 | 容器与根导航器的系统属性转发 | 状态栏、旋转及全面屏设备待人工验收 |
| 第一响应者、标题和 tabBarItem | 包装器向内容页面转发 | 静态核查；设备待验收 |
| 普通、禁返回、隐藏栏、滚动用例 | DemoPageController 对应模式 | 与源九类入口逐项对应 |
| Push 后移除、自定义栏、自定义动画 | DemoPageController 对应模式 | 与源九类入口逐项对应 |
| 工具栏/Web、隐藏状态栏 | WKWebView、本地 HTML、toolbarItems | 与源九类入口逐项对应 |

## 明确接受的差异

- iOS 下限调整为 13，公开 API 按 Swift 设计，页面覆盖方法改为定制协议。
- 自有源码全部为 Swift；允许 Objective-C runtime 关联对象，不继续依赖 Objective-C RTInteractivePush。
- 源库无条件覆盖子页面 appearance 的行为改为显式开启继承；默认保留独立外观。
- Demo 使用现代纯代码页面，Web 改用 WKWebView 和本地 HTML，额外保留 Storyboard 兼容夹具。
- 不复制原回调演示的强引用捕获；演示采用弱引用。
- 删除最后一个页面时保持现有根页面，避免产生空导航栈。
