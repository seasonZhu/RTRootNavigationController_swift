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
