import UIKit

/// 内部导航栈的页面包装器。通过 contentViewController 访问真实页面。
open class RTContainerController: UIViewController {
    /// 包装器持有的真实内容页面。
    /// 业务读取页面栈时优先使用根导航器的 `rt.viewControllers`，无需自行拆解包装器。
    public let contentViewController: UIViewController

    /// 为内容页面提供独立导航栏的内部导航器，只允许框架设置。
    /// 使用不包装导航栏的根页面初始化方式时为 `nil`。
    public private(set) var containerNavigationController: RTContainerNavigationController?
    private var backPlaceholder: UIViewController?

    init(content: UIViewController, wrapping: Bool = true, previous: UIViewController? = nil, systemBack: Bool = false) {
        contentViewController = content

        super.init(nibName: nil, bundle: nil)
        let child: UIViewController
        if wrapping {
            let navigation = RTContainerNavigationController(navigationBarClass: content.navigationCustomization?.navigationBarClass, toolbarClass: nil)
            containerNavigationController = navigation
            var stack: [UIViewController] = []
            if systemBack, let previous {
                let placeholder = UIViewController()
                backPlaceholder = placeholder
                placeholder.title = previous.navigationItem.title ?? previous.title
                placeholder.navigationItem.backBarButtonItem = previous.navigationItem.backBarButtonItem
                stack.append(placeholder)
            }
            navigation.setLocalViewControllers(stack + [content])
            child = navigation
        } else {
            child = content
        }
        addChild(child)
        child.didMove(toParent: self)
    }

    func configurePrevious(_ previous: UIViewController?, systemBack: Bool) {
        guard let navigation = containerNavigationController else { return }
        if systemBack, let previous {
            if backPlaceholder == nil {
                let placeholder = UIViewController()
                backPlaceholder = placeholder
                navigation.setLocalViewControllers([placeholder, contentViewController])
            }
            backPlaceholder?.title = previous.navigationItem.title ?? previous.title
            backPlaceholder?.navigationItem.backBarButtonItem = previous.navigationItem.backBarButtonItem
        } else if backPlaceholder != nil {
            backPlaceholder = nil
            navigation.setLocalViewControllers([contentViewController])
        }
    }

    @available(*, unavailable)

    /// 不支持从归档直接创建包装器；包装器由根导航器自动创建。
    public required init?(coder: NSCoder) { fatalError("包装器由根导航器创建") }

    /// 加载容器视图并配置内部导航行为。
    /// 重写时应调用 `super`，以保留页面嵌入、手势或外观设置。
    open override func viewDidLoad() {
        super.viewDidLoad()
        let child = containerNavigationController ?? contentViewController
        child.view.frame = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(child.view)
    }

    /// 提供状态栏样式的子页面。
    open override var childForStatusBarStyle: UIViewController? { contentViewController }

    /// 提供状态栏显隐状态的子页面。
    open override var childForStatusBarHidden: UIViewController? { contentViewController }

    /// 当前内容页面要求的状态栏样式。
    open override var preferredStatusBarStyle: UIStatusBarStyle { contentViewController.preferredStatusBarStyle }

    /// 当前内容页面是否隐藏状态栏。
    open override var prefersStatusBarHidden: Bool { contentViewController.prefersStatusBarHidden }

    /// 当前内容页面的状态栏更新动画。
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { contentViewController.preferredStatusBarUpdateAnimation }

    /// 提供 Home 指示条自动隐藏策略的子页面。
    open override var childForHomeIndicatorAutoHidden: UIViewController? { contentViewController }

    /// 提供系统边缘手势延迟策略的子页面。
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? { contentViewController }

    /// 内容页面是否自动隐藏 Home 指示条。
    open override var prefersHomeIndicatorAutoHidden: Bool { contentViewController.prefersHomeIndicatorAutoHidden }

    /// 内容页面要求延迟系统手势的屏幕边缘。
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { contentViewController.preferredScreenEdgesDeferringSystemGestures }

    /// 当前内容页面是否允许自动旋转。
    open override var shouldAutorotate: Bool { contentViewController.shouldAutorotate }

    /// 当前内容页面支持的屏幕方向。
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { contentViewController.supportedInterfaceOrientations }

    /// 当前内容页面展示时优先使用的屏幕方向。
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { contentViewController.preferredInterfaceOrientationForPresentation }

    /// 内容页面是否可以成为第一响应者。
    open override var canBecomeFirstResponder: Bool { contentViewController.canBecomeFirstResponder }

    /// 请求内容页面成为第一响应者。
    /// - Returns: 内容页面是否成功成为第一响应者。
    open override func becomeFirstResponder() -> Bool { contentViewController.becomeFirstResponder() }

    /// 转发内容页面的底部栏隐藏设置；应在入栈前配置
    open override var hidesBottomBarWhenPushed: Bool {
        get { contentViewController.hidesBottomBarWhenPushed }
        set { contentViewController.hidesBottomBarWhenPushed = newValue }
    }

    /// 转发内容页面的标题，读写均作用于真实页面。
    open override var title: String? {
        get { contentViewController.title }
        set { contentViewController.title = newValue }
    }

    /// 转发内容页面的 TabBar 项目，读写均作用于真实页面。
    open override var tabBarItem: UITabBarItem! {
        get { contentViewController.tabBarItem }
        set { contentViewController.tabBarItem = newValue }
    }
}

/// 页面看到的导航器，将栈操作转发给外层根导航器。
open class RTContainerNavigationController: UINavigationController {
    private var root: RTRootNavigationController? { parent?.rt.navigationController }
    private var localTop: UIViewController? { super.topViewController }

    func setLocalViewControllers(_ controllers: [UIViewController]) {
        super.setViewControllers(controllers, animated: false)
    }

    /// 加载容器视图并配置内部导航行为。
    /// 重写时应调用 `super`，以保留页面嵌入、手势或外观设置。
    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.isEnabled = false
        if let root { root.applyAppearance(to: self) }
    }

    /// 布局完成后同步已启用的根导航栏外观。
    /// 重写时应调用 `super`。
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let root { root.applyAppearance(to: self) }
    }

    /// 按入栈顺序返回真实内容页面数组。
    /// 存在根导航器时读写其完整业务栈，否则使用内部局部栈。
    open override var viewControllers: [UIViewController] {
        get { root?.rt.viewControllers ?? super.viewControllers }
        set { setViewControllers(newValue, animated: false) }
    }

    /// 以内容页面数组替换真实导航栈，自动复用或创建包装器。
    /// 数组不能包含重复页面实例，否则触发前置条件失败。
    /// 挂接根导航器时转发操作，否则执行 UIKit 的局部导航操作。
    /// - Parameters:
    ///   - viewControllers: 按顺序排列的页面数组。
    ///   - animated: 是否执行导航转场动画。
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if let root { root.setViewControllers(viewControllers, animated: animated) }
        else { super.setViewControllers(viewControllers, animated: animated) }
    }

    /// 将内容页面压入真实导航栈，并自动创建独立导航栏包装器。
    /// 同一页面实例不能重复入栈，否则触发前置条件失败。
    /// 挂接根导航器时转发操作，否则执行 UIKit 的局部导航操作。
    /// - Parameters:
    ///   - viewController: 目标页面实例。
    ///   - animated: 是否执行导航转场动画。
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let root { root.pushViewController(viewController, animated: animated) }
        else { super.pushViewController(viewController, animated: animated) }
    }

    /// 移除栈顶页面并返回真实内容页面；不能返回时为 `nil`。
    /// 挂接根导航器时转发操作，否则执行 UIKit 的局部导航操作。
    /// - Parameters:
    ///   - animated: 是否执行导航转场动画。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult open override func popViewController(animated: Bool) -> UIViewController? {
        if let root { return root.popViewController(animated: animated) }
        return super.popViewController(animated: animated)
    }

    /// 返回指定内容页面或包装器，返回被移除的真实内容页面数组。
    /// 目标不在栈中时返回 `nil`；目标已经位于栈顶时通常返回空数组。
    /// 挂接根导航器时转发操作，否则执行 UIKit 的局部导航操作。
    /// - Parameters:
    ///   - viewController: 目标页面实例。
    ///   - animated: 是否执行导航转场动画。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        if let root { return root.popToViewController(viewController, animated: animated) }
        return super.popToViewController(viewController, animated: animated)
    }

    /// 返回根页面，返回被移除的真实内容页面数组；空栈时为 `nil`。
    /// 挂接根导航器时转发操作，否则执行 UIKit 的局部导航操作。
    /// - Parameters:
    ///   - animated: 是否执行导航转场动画。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        if let root { return root.popToRootViewController(animated: animated) }
        return super.popToRootViewController(animated: animated)
    }

    /// 业务导航代理，由框架弱引用保存，应由调用方保持其生命周期。
    /// 根导航器保留内部 UIKit 代理职责，并将页面显示及动画等受支持的回调转发给业务代理。
    open override var delegate: UINavigationControllerDelegate? {
        get { root?.delegate ?? super.delegate }
        set {
            if let root { root.delegate = newValue }
            else { super.delegate = newValue }
        }
    }

    /// 查询关联的 TabBar 容器。
    /// 若外层根导航器属于该 TabBar，且底部栏不透明或栈内页面要求隐藏底部栏，则返回 `nil`。
    open override var tabBarController: UITabBarController? {
        guard let tab = super.tabBarController, let root else { return super.tabBarController }
        if root.tabBarController !== tab { return tab }
        return !tab.tabBar.isTranslucent || root.rt.viewControllers.contains(where: { $0.hidesBottomBarWhenPushed }) ? nil : tab
    }

    /// 提供状态栏样式的子页面。
    open override var childForStatusBarStyle: UIViewController? { localTop }

    /// 提供状态栏显隐状态的子页面。
    open override var childForStatusBarHidden: UIViewController? { localTop }

    /// 提供 Home 指示条自动隐藏策略的子页面。
    open override var childForHomeIndicatorAutoHidden: UIViewController? { localTop }

    /// 提供系统边缘手势延迟策略的子页面。
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? { localTop }

    /// 当前内容页面要求的状态栏样式。
    open override var preferredStatusBarStyle: UIStatusBarStyle { localTop?.preferredStatusBarStyle ?? .default }

    /// 当前内容页面是否隐藏状态栏。
    open override var prefersStatusBarHidden: Bool { localTop?.prefersStatusBarHidden ?? false }

    /// 当前内容页面的状态栏更新动画。
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { localTop?.preferredStatusBarUpdateAnimation ?? .fade }

    /// 当前内容页面是否允许自动旋转。
    open override var shouldAutorotate: Bool { localTop?.shouldAutorotate ?? true }

    /// 当前内容页面支持的屏幕方向。
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { localTop?.supportedInterfaceOrientations ?? .all }

    /// 当前内容页面展示时优先使用的屏幕方向。
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { localTop?.preferredInterfaceOrientationForPresentation ?? .portrait }

    /// 向根导航器查询 Storyboard unwind 可用的子控制器；未挂接根导航器时使用 UIKit 默认实现。
    /// - Parameter source: 发起 unwind 的来源信息。
    /// - Returns: 可以参与 unwind 搜索的子控制器数组。
    open override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        root?.allowedChildrenForUnwinding(from: source) ?? super.allowedChildrenForUnwinding(from: source)
    }
}
