import UIKit

/// 内部导航栈的页面包装器。通过 contentViewController 访问真实页面。
open class RTContainerController: UIViewController {
    public let contentViewController: UIViewController
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
    public required init?(coder: NSCoder) { fatalError("包装器由根导航器创建") }

    open override func viewDidLoad() {
        super.viewDidLoad()
        let child = containerNavigationController ?? contentViewController
        child.view.frame = view.bounds
        child.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(child.view)
    }

    open override var childForStatusBarStyle: UIViewController? { contentViewController }
    open override var childForStatusBarHidden: UIViewController? { contentViewController }
    open override var preferredStatusBarStyle: UIStatusBarStyle { contentViewController.preferredStatusBarStyle }
    open override var prefersStatusBarHidden: Bool { contentViewController.prefersStatusBarHidden }
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { contentViewController.preferredStatusBarUpdateAnimation }
    open override var childForHomeIndicatorAutoHidden: UIViewController? { contentViewController }
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? { contentViewController }
    open override var prefersHomeIndicatorAutoHidden: Bool { contentViewController.prefersHomeIndicatorAutoHidden }
    open override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { contentViewController.preferredScreenEdgesDeferringSystemGestures }
    open override var shouldAutorotate: Bool { contentViewController.shouldAutorotate }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { contentViewController.supportedInterfaceOrientations }
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { contentViewController.preferredInterfaceOrientationForPresentation }
    open override var canBecomeFirstResponder: Bool { contentViewController.canBecomeFirstResponder }
    open override func becomeFirstResponder() -> Bool { contentViewController.becomeFirstResponder() }
    open override var hidesBottomBarWhenPushed: Bool {
        get { contentViewController.hidesBottomBarWhenPushed }
        set { contentViewController.hidesBottomBarWhenPushed = newValue }
    }
    open override var title: String? {
        get { contentViewController.title }
        set { contentViewController.title = newValue }
    }
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

    open override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.isEnabled = false
        if let root { root.applyAppearance(to: self) }
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let root { root.applyAppearance(to: self) }
    }

    open override var viewControllers: [UIViewController] {
        get { root?.rt.viewControllers ?? super.viewControllers }
        set { setViewControllers(newValue, animated: false) }
    }
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if let root { root.setViewControllers(viewControllers, animated: animated) }
        else { super.setViewControllers(viewControllers, animated: animated) }
    }
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let root { root.pushViewController(viewController, animated: animated) }
        else { super.pushViewController(viewController, animated: animated) }
    }
    @discardableResult open override func popViewController(animated: Bool) -> UIViewController? {
        if let root { return root.popViewController(animated: animated) }
        return super.popViewController(animated: animated)
    }
    @discardableResult open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        if let root { return root.popToViewController(viewController, animated: animated) }
        return super.popToViewController(viewController, animated: animated)
    }
    @discardableResult open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        if let root { return root.popToRootViewController(animated: animated) }
        return super.popToRootViewController(animated: animated)
    }
    open override var delegate: UINavigationControllerDelegate? {
        get { root?.delegate ?? super.delegate }
        set {
            if let root { root.delegate = newValue }
            else { super.delegate = newValue }
        }
    }
    open override var tabBarController: UITabBarController? {
        guard let tab = super.tabBarController, let root else { return super.tabBarController }
        if root.tabBarController !== tab { return tab }
        return !tab.tabBar.isTranslucent || root.rt.viewControllers.contains(where: { $0.hidesBottomBarWhenPushed }) ? nil : tab
    }
    open override var childForStatusBarStyle: UIViewController? { localTop }
    open override var childForStatusBarHidden: UIViewController? { localTop }
    open override var childForHomeIndicatorAutoHidden: UIViewController? { localTop }
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? { localTop }
    open override var preferredStatusBarStyle: UIStatusBarStyle { localTop?.preferredStatusBarStyle ?? .default }
    open override var prefersStatusBarHidden: Bool { localTop?.prefersStatusBarHidden ?? false }
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { localTop?.preferredStatusBarUpdateAnimation ?? .fade }
    open override var shouldAutorotate: Bool { localTop?.shouldAutorotate ?? true }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { localTop?.supportedInterfaceOrientations ?? .all }
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { localTop?.preferredInterfaceOrientationForPresentation ?? .portrait }
    open override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        root?.allowedChildrenForUnwinding(from: source) ?? super.allowedChildrenForUnwinding(from: source)
    }
}
