import UIKit

/// 为每个内容页面提供独立导航栏，外层负责真实导航栈和转场。
open class RTRootNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    /// 是否使用系统返回按钮，默认为 `false`。
    /// 设为 `true` 时通过占位页面提供上一页标题及 `backBarButtonItem`；建议在页面入栈前设置。
    public var useSystemBackBarButtonItem = false

    /// 是否将根导航栏及根页面外观复制到页面导航栏，默认为 `false`。
    /// 启用后在页面显示与布局时复制外观，可能覆盖页面单独设置的导航栏样式。
    public var transferNavigationBarAttributes = false

    /// 框架生成的返回按钮点击回调，默认为 `nil`，此时自动返回上一页。
    /// 设置后由调用方决定是否执行 pop；系统按钮、侧滑和程序化返回不经过此回调。
    /// 闭包应使用弱引用捕获页面或根导航器，避免循环引用。
    public var onBackCallback: (() -> Void)?

    /// 是否启用边缘拖动进入下一页，默认为 `true`，修改后立即更新手势开关。
    /// 下一页由当前活动页面的 `nextSiblingController()` 提供；从右边缘左拖，RTL 时方向相反。
    public var isInteractivePushEnabled = true {
        didSet { pushGesture?.isEnabled = isInteractivePushEnabled }
    }

    private weak var forwardedDelegate: UINavigationControllerDelegate?
    private var pendingCompletion: ((Bool) -> Void)?
    private weak var completionTarget: UIViewController?
    private var completionGeneration: UInt = 0
    private var pushGesture: UIScreenEdgePanGestureRecognizer?
    private var pushInteraction: UIPercentDrivenInteractiveTransition?
    private var interactionAnimator: RTSlideAnimator?
    private var preparedNextController: UIViewController?
    private var isTransitioning = false
    private var generatedBackItems: [ObjectIdentifier: WeakBarItem] = [:]

    /// 以真实内容页面创建根导航器，并为其建立独立导航栏。
    /// - Parameter rootViewController: 导航栈的首个内容页面，不应预先嵌入普通导航器。
    public override init(rootViewController: UIViewController) {
        super.init(navigationBarClass: nil, toolbarClass: nil)
        super.setViewControllers([wrap(rootViewController, previous: nil)], animated: false)
    }

    /// 创建根导航器，但不为根页面再添加独立导航栏。
    /// 适合根页面为自带页面导航器的 TabBar 容器；后续 Push 仍按普通页面包装。
    /// - Parameter rootViewController: 不需要额外导航栏包装的根页面。
    public init(rootViewControllerNoWrapping rootViewController: UIViewController) {
        super.init(navigationBarClass: nil, toolbarClass: nil)
        super.setViewControllers([RTContainerController(content: rootViewController, wrapping: false)], animated: false)
    }

    /// 创建尚未设置内容栈的根导航器；外层导航栏保持隐藏。
    /// - Parameters:
    ///   - navigationBarClass: 外层导航栏类型；页面导航栏类型通过定制协议配置。
    ///   - toolbarClass: 外层工具栏类型。
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }

    /// 从归档恢复控制器。
    /// - Parameter coder: Storyboard 或归档提供的解码器。
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    /// 从 Storyboard 加载后，将现有页面栈转换为框架包装栈。
    /// 重写时应调用 `super`。
    open override func awakeFromNib() {
        super.awakeFromNib()
        setViewControllers(super.viewControllers, animated: false)
    }

    /// 加载容器视图并配置内部导航行为。
    /// 重写时应调用 `super`，以保留页面嵌入、手势或外观设置。
    open override func viewDidLoad() {
        super.viewDidLoad()
        super.delegate = self
        super.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .systemBackground
        interactivePopGestureRecognizer?.delegate = self
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePushGesture(_:)))
        gesture.edges = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        gesture.delegate = self
        gesture.isEnabled = isInteractivePushEnabled
        view.addGestureRecognizer(gesture)
        pushGesture = gesture
        updateVisibleState()
    }

    /// 保持外层导航栏隐藏，此方法不改变外层导航栏状态。
    /// - Parameters:
    ///   - hidden: 请求的显隐值，外层忽略此值；页面请操作自己的导航器。
    ///   - animated: 请求的动画开关，外层不执行显隐动画。
    open override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {}

    /// 业务导航代理，由框架弱引用保存，应由调用方保持其生命周期。
    /// 根导航器保留内部 UIKit 代理职责，并将页面显示及动画等受支持的回调转发给业务代理。
    open override var delegate: UINavigationControllerDelegate? {
        get { forwardedDelegate }
        set { forwardedDelegate = newValue }
    }

    static func unwrap(_ controller: UIViewController) -> UIViewController {
        (controller as? RTContainerController)?.contentViewController ?? controller
    }

    private func wrap(_ controller: UIViewController, previous: UIViewController?) -> UIViewController {
        if let container = controller as? RTContainerController {
            container.configurePrevious(previous, systemBack: useSystemBackBarButtonItem)
            return container
        }
        if let existing = super.viewControllers.first(where: { Self.unwrap($0) === controller }) as? RTContainerController {
            existing.configurePrevious(previous, systemBack: useSystemBackBarButtonItem)
            return existing
        }
        return RTContainerController(content: controller, previous: previous, systemBack: useSystemBackBarButtonItem)
    }

    /// 将内容页面压入真实导航栈，并自动创建独立导航栏包装器。
    /// 同一页面实例不能重复入栈，否则触发前置条件失败。
    /// - Parameters:
    ///   - viewController: 目标页面实例。
    ///   - animated: 是否执行导航转场动画。
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        precondition(!rt.viewControllers.contains(where: { $0 === viewController }), "同一页面不能重复入栈")
        super.pushViewController(wrap(viewController, previous: rt.topViewController), animated: animated)
        if !animated { updateVisibleState() }
    }

    /// 以内容页面数组替换真实导航栈，自动复用或创建包装器。
    /// 数组不能包含重复页面实例，否则触发前置条件失败。
    /// - Parameters:
    ///   - viewControllers: 按顺序排列的页面数组。
    ///   - animated: 是否执行导航转场动画。
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        let contents = viewControllers.map(Self.unwrap)
        precondition(Set(contents.map(ObjectIdentifier.init)).count == contents.count, "导航栈不能包含重复页面")
        let wrapped = viewControllers.enumerated().map { index, controller in
            wrap(controller, previous: index > 0 ? contents[index - 1] : nil)
        }
        super.setViewControllers(wrapped, animated: animated)
        if !animated { updateVisibleState() }
    }

    /// 移除栈顶页面并返回真实内容页面；不能返回时为 `nil`。
    /// - Parameters:
    ///   - animated: 是否执行导航转场动画。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult open override func popViewController(animated: Bool) -> UIViewController? {
        let popped = super.popViewController(animated: animated).map(Self.unwrap)
        if !animated { updateVisibleState() }
        return popped
    }

    /// 返回指定内容页面或包装器，返回被移除的真实内容页面数组。
    /// 目标不在栈中时返回 `nil`；目标已经位于栈顶时通常返回空数组。
    /// - Parameters:
    ///   - viewController: 目标页面实例。
    ///   - animated: 是否执行导航转场动画。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        guard let target = super.viewControllers.first(where: { $0 === viewController || Self.unwrap($0) === viewController }) else { return nil }
        let popped = super.popToViewController(target, animated: animated)?.map(Self.unwrap)
        if !animated { updateVisibleState() }
        return popped
    }

    /// 返回根页面，返回被移除的真实内容页面数组；空栈时为 `nil`。
    /// - Parameters:
    ///   - animated: 是否执行导航转场动画。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        guard let root = rt.viewControllers.first else { return nil }
        return popToViewController(root, animated: animated)
    }

    /// 从导航栈移除指定页面或其包装器。
    /// 目标不在栈中或移除后将形成空栈时不执行；此方法没有完成回调。
    /// - Parameters:
    ///   - controller: 要移除的内容页面或包装器实例。
    ///   - animated: 是否使用动画，默认为 `false`。
    public func removeViewController(_ controller: UIViewController, animated: Bool = false) {
        let stack = super.viewControllers.filter { $0 !== controller && Self.unwrap($0) !== controller }
        guard stack.count != super.viewControllers.count, !stack.isEmpty else { return }
        setViewControllers(stack, animated: animated)
    }

    /// 将内容页面压入真实导航栈，并自动创建独立导航栏包装器。
    /// 同一页面实例不能重复入栈，否则触发前置条件失败。
    /// - Parameters:
    ///   - controller: 目标页面实例。
    ///   - animated: 是否执行导航转场动画。
    ///   - completion: 完成返回 `true`，取消或被后续带回调操作替换时返回 `false`。
    ///     无动画或无操作时可同步调用；旧回调若重入发起新操作，当前操作停止。
    public func pushViewController(_ controller: UIViewController, animated: Bool, completion: @escaping (Bool) -> Void) {
        guard let generation = beginCompletion(completion) else { return }
        completionTarget = controller
        pushViewController(controller, animated: animated)
        finishWithoutTransitionIfNeeded(animated: animated, generation: generation)
    }

    /// 移除栈顶页面并返回真实内容页面；不能返回时为 `nil`。
    /// - Parameters:
    ///   - animated: 是否执行导航转场动画。
    ///   - completion: 完成返回 `true`，取消或被后续带回调操作替换时返回 `false`。
    ///     无动画或无操作时可同步调用；旧回调若重入发起新操作，当前操作停止。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult public func popViewController(animated: Bool, completion: @escaping (Bool) -> Void) -> UIViewController? {
        guard let generation = beginCompletion(completion) else { return nil }
        completionTarget = rt.viewControllers.dropLast().last
        let result = popViewController(animated: animated)
        finishWithoutTransitionIfNeeded(animated: animated && result != nil, generation: generation)
        return result
    }

    /// 返回指定内容页面或包装器，返回被移除的真实内容页面数组。
    /// 目标不在栈中时返回 `nil`；目标已经位于栈顶时通常返回空数组。
    /// - Parameters:
    ///   - controller: 目标页面实例。
    ///   - animated: 是否执行导航转场动画。
    ///   - completion: 完成返回 `true`，取消或被后续带回调操作替换时返回 `false`。
    ///     无动画或无操作时可同步调用；旧回调若重入发起新操作，当前操作停止。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult public func popToViewController(_ controller: UIViewController, animated: Bool, completion: @escaping (Bool) -> Void) -> [UIViewController]? {
        guard let generation = beginCompletion(completion) else { return nil }
        completionTarget = controller
        let result = popToViewController(controller, animated: animated)
        finishWithoutTransitionIfNeeded(animated: animated && !(result?.isEmpty ?? true), generation: generation)
        return result
    }

    /// 返回根页面，返回被移除的真实内容页面数组；空栈时为 `nil`。
    /// - Parameters:
    ///   - animated: 是否执行导航转场动画。
    ///   - completion: 完成返回 `true`，取消或被后续带回调操作替换时返回 `false`。
    ///     无动画或无操作时可同步调用；旧回调若重入发起新操作，当前操作停止。
    /// - Returns: 本次移除的真实内容页面；没有对应结果时为 `nil`。
    @discardableResult public func popToRootViewController(animated: Bool, completion: @escaping (Bool) -> Void) -> [UIViewController]? {
        guard let generation = beginCompletion(completion) else { return nil }
        completionTarget = rt.viewControllers.first
        let result = popToRootViewController(animated: animated)
        finishWithoutTransitionIfNeeded(animated: animated && !(result?.isEmpty ?? true), generation: generation)
        return result
    }

    private func beginCompletion(_ completion: @escaping (Bool) -> Void) -> UInt? {
        completionGeneration &+= 1
        let generation = completionGeneration
        let previous = pendingCompletion
        pendingCompletion = completion
        completionTarget = nil
        previous?(false)
        // 旧回调可同步发起新操作，此时外层操作已被替换，不能继续修改导航栈。
        return completionGeneration == generation ? generation : nil
    }

    private func finishWithoutTransitionIfNeeded(animated: Bool, generation: UInt) {
        // 同步 didShow 的用户回调也可能开启下一次操作。
        guard pendingCompletion != nil, completionGeneration == generation else { return }
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { [weak self] context in
                guard let self, self.completionGeneration == generation else { return }
                self.resolveCompletion(!context.isCancelled)
            }
        } else if !animated || !isTransitioning {
            resolveCompletion(true)
        }
    }

    private func resolveCompletion(_ finished: Bool) {
        let completion = pendingCompletion
        pendingCompletion = nil
        completionTarget = nil
        completion?(finished)
    }

    /// 处理框架生成的返回按钮事件。
    /// 存在 `onBackCallback` 时仅调用回调，否则执行带动画的单页返回。
    /// - Parameter sender: 触发事件的对象，允许为 `nil`。
    @objc open func onBack(_ sender: Any?) {
        if let onBackCallback { onBackCallback() }
        else { popViewController(animated: true) }
    }

    private func installBackItem(on content: UIViewController) {
        guard content !== rt.viewControllers.first, !useSystemBackBarButtonItem,
              content.navigationItem.leftBarButtonItem == nil else { return }
        let item = content.navigationCustomization?.customBackItem(target: self, action: #selector(onBack(_:)))
            ?? UIBarButtonItem(title: NSLocalizedString("Back", comment: "返回按钮"), style: .plain, target: self, action: #selector(onBack(_:)))
        content.navigationItem.leftBarButtonItem = item
        generatedBackItems[ObjectIdentifier(content)] = WeakBarItem(item)
    }

    private func updateVisibleState() {
        generatedBackItems = generatedBackItems.filter { $0.value.item != nil }
        guard let content = rt.topViewController else { return }
        // 回到根页面时移除由框架生成、但已不需要的返回按钮。
        if content === rt.viewControllers.first,
           let generated = generatedBackItems[ObjectIdentifier(content)]?.item,
           content.navigationItem.leftBarButtonItem === generated {
            content.navigationItem.leftBarButtonItem = nil
        }
        installBackItem(on: content)
        interactivePopGestureRecognizer?.isEnabled = rt.viewControllers.count > 1
        setNeedsStatusBarAppearanceUpdate()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    func applyAppearance(to navigation: RTContainerNavigationController) {
        guard transferNavigationBarAttributes else { return }
        let source = navigationBar
        let destination = navigation.navigationBar
        destination.isTranslucent = source.isTranslucent
        destination.tintColor = source.tintColor
        destination.barTintColor = source.barTintColor
        destination.barStyle = source.barStyle
        destination.backgroundColor = source.backgroundColor
        destination.titleTextAttributes = source.titleTextAttributes
        destination.largeTitleTextAttributes = source.largeTitleTextAttributes
        destination.prefersLargeTitles = source.prefersLargeTitles
        destination.shadowImage = source.shadowImage
        destination.backIndicatorImage = source.backIndicatorImage
        destination.backIndicatorTransitionMaskImage = source.backIndicatorTransitionMaskImage
        for metrics in [UIBarMetrics.default, .compact] {
            destination.setBackgroundImage(source.backgroundImage(for: metrics), for: metrics)
            destination.setTitleVerticalPositionAdjustment(source.titleVerticalPositionAdjustment(for: metrics), for: metrics)
        }
        destination.standardAppearance = source.standardAppearance.copy()
        destination.scrollEdgeAppearance = source.scrollEdgeAppearance?.copy() as? UINavigationBarAppearance
        destination.compactAppearance = source.compactAppearance?.copy() as? UINavigationBarAppearance
        if #available(iOS 15.0, *) { destination.compactScrollEdgeAppearance = source.compactScrollEdgeAppearance?.copy() as? UINavigationBarAppearance }
        if #available(iOS 16.0, *) { destination.preferredBehavioralStyle = source.preferredBehavioralStyle }
        guard let sourceItem = rt.viewControllers.first?.navigationItem,
              let item = navigation.topViewController?.navigationItem,
              sourceItem !== item else { return }
        item.standardAppearance = sourceItem.standardAppearance?.copy() as? UINavigationBarAppearance
        item.scrollEdgeAppearance = sourceItem.scrollEdgeAppearance?.copy() as? UINavigationBarAppearance
        if #available(iOS 14.0, *) {
            item.compactAppearance = sourceItem.compactAppearance?.copy() as? UINavigationBarAppearance
            if sourceItem.backButtonDisplayMode != .default { item.backButtonDisplayMode = sourceItem.backButtonDisplayMode }
        }
        if #available(iOS 15.0, *) { item.compactScrollEdgeAppearance = sourceItem.compactScrollEdgeAppearance?.copy() as? UINavigationBarAppearance }
        if #available(iOS 16.0, *), let provider = sourceItem.titleMenuProvider { item.titleMenuProvider = provider }
    }

    /// UIKit 显示前回调：标记转场状态、应用外观，并向业务代理传递解包后的内容页面。
    /// 由 UIKit 调用，业务方应设置 `delegate` 接收通知。
    /// - Parameters:
    ///   - navigationController: UIKit 发起回调的导航器。
    ///   - viewController: 即将显示的包装器，转发时解包为内容页面。
    ///   - animated: 本次显示是否使用动画。
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        isTransitioning = true
        let content = Self.unwrap(viewController)
        if let container = viewController as? RTContainerController, let inner = container.containerNavigationController { applyAppearance(to: inner) }
        forwardedDelegate?.navigationController?(self, willShow: content, animated: animated)
    }

    /// UIKit 显示后回调：更新返回按钮和手势、结算完成回调，并通知业务代理真实页面。
    /// 由 UIKit 调用，业务方不应手动触发。
    /// - Parameters:
    ///   - navigationController: UIKit 发起回调的导航器。
    ///   - viewController: 已显示的包装器，转发时解包为内容页面。
    ///   - animated: 本次显示是否使用动画。
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        isTransitioning = false
        updateVisibleState()
        resolveCompletion(completionTarget == nil || completionTarget === Self.unwrap(viewController))
        forwardedDelegate?.navigationController?(self, didShow: Self.unwrap(viewController), animated: animated)
    }

    /// 为 UIKit 选择转场动画。
    /// 依次优先使用内建交互 Push 动画、业务代理动画、页面定制动画；均为空时返回 `nil`。
    /// - Parameters:
    ///   - navigationController: 请求动画的导航器。
    ///   - operation: 本次导航操作类型。
    ///   - fromVC: 转场来源控制器，选择页面动画前会解包。
    ///   - toVC: 转场目标控制器，选择页面动画前会解包。
    /// - Returns: 本次使用的动画对象，或 `nil` 使用 UIKit 默认转场。
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let interactionAnimator { return interactionAnimator }
        let from = Self.unwrap(fromVC), to = Self.unwrap(toVC)
        if let external = forwardedDelegate?.navigationController?(self, animationControllerFor: operation, from: from, to: to) { return external }
        return (operation == .push ? to : from).navigationCustomization?.animatedTransitioning
    }

    /// 为 UIKit 选择交互控制器。
    /// 依次优先使用内建 Push 交互控制器、业务代理返回值、自定义动画提供的交互控制器。
    /// - Parameters:
    ///   - navigationController: 请求交互控制器的导航器。
    ///   - animationController: 已选定的本次转场动画。
    /// - Returns: 交互控制器，或 `nil` 表示无交互控制。
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let pushInteraction { return pushInteraction }
        return forwardedDelegate?.navigationController?(self, interactionControllerFor: animationController)
            ?? (animationController as? RTViewControllerAnimatedTransitioning)?.interactiveTransitioning
    }

    /// 查询业务代理支持的方向；代理未提供时使用当前页面的方向配置。
    /// - Parameter navigationController: UIKit 发起查询的导航器。
    /// - Returns: 可用屏幕方向掩码。
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        forwardedDelegate?.navigationControllerSupportedInterfaceOrientations?(self) ?? supportedInterfaceOrientations
    }

    /// 查询业务代理首选展示方向；代理未提供时使用当前页面的配置。
    /// - Parameter navigationController: UIKit 发起查询的导航器。
    /// - Returns: 首选屏幕方向。
    public func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        forwardedDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(self) ?? preferredInterfaceOrientationForPresentation
    }

    /// 判定是否允许开始边缘 Push 或 Pop；转场期间拒绝新手势。
    /// Push 需提供未入栈的下一页；Pop 需存在上一页且页面策略允许。
    /// - Parameter gestureRecognizer: 请求开始的手势。
    /// - Returns: 是否允许开始。
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !isTransitioning, transitionCoordinator == nil else { return false }
        if gestureRecognizer === pushGesture {
            guard isInteractivePushEnabled, let next = activeContent?.navigationCustomization?.nextSiblingController(),
                  !rt.viewControllers.contains(where: { $0 === next }) else { return false }
            preparedNextController = next
            return true
        }
        guard rt.viewControllers.count > 1, let content = activeContent else { return false }
        if content.hasExplicitPopPreference { return !content.rt.isInteractivePopDisabled }
        let left = content.navigationItem.leftBarButtonItem
        let isGenerated = left != nil && left === generatedBackItems[ObjectIdentifier(rt.topViewController ?? content)]?.item
        return content.navigationController?.isNavigationBarHidden != true && (left == nil || isGenerated)
    }

    /// 允许边缘返回与其他手势同时识别。
    /// - Parameters:
    ///   - gestureRecognizer: 当前参与判定的手势。
    ///   - otherGestureRecognizer: 与其竞争的另一手势。
    /// - Returns: 当前手势为根导航器的边缘返回手势时为 `true`。
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === interactivePopGestureRecognizer
    }

    /// 向 UIKit 声明边缘返回的失败依赖关系。
    /// - Parameters:
    ///   - gestureRecognizer: 当前参与判定的手势。
    ///   - otherGestureRecognizer: 与其竞争的另一手势。
    /// - Returns: 当前手势为根导航器的边缘返回手势时为 `true`。
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === interactivePopGestureRecognizer
    }

    private var activeContent: UIViewController? {
        var current = rt.topViewController
        while true {
            if let tab = current as? UITabBarController { current = tab.selectedViewController }
            else if let navigation = current as? UINavigationController { current = navigation.topViewController }
            else { return current }
        }
    }

    @objc private func handlePushGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let sign: CGFloat = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? 1 : -1
        let width = max(view.bounds.width, 1)
        let progress = min(max(sign * gesture.translation(in: view).x / width, 0), 1)
        switch gesture.state {
        case .began:
            guard let next = preparedNextController else { return }
            preparedNextController = nil
            let interaction = UIPercentDrivenInteractiveTransition()
            pushInteraction = interaction
            interactionAnimator = RTSlideAnimator(direction: sign)
            pushViewController(next, animated: true)
        case .changed: pushInteraction?.update(progress)
        case .ended:
            let finish = RTInteractionDecision.shouldFinish(progress: progress, velocity: sign * gesture.velocity(in: view).x)
            if finish { pushInteraction?.finish() } else { pushInteraction?.cancel() }
            clearPushInteractionAfterTransition()
        case .cancelled, .failed:
            pushInteraction?.cancel()
            clearPushInteractionAfterTransition()
        default: break
        }
    }

    private func clearPushInteractionAfterTransition() {
        // UIKit 已持有交互控制器；及时清空，避免下一次导航误用它。
        pushInteraction = nil
        interactionAnimator = nil
        preparedNextController = nil
    }

    /// 提供状态栏样式的子页面。
    open override var childForStatusBarStyle: UIViewController? { rt.topViewController }

    /// 提供状态栏显隐状态的子页面。
    open override var childForStatusBarHidden: UIViewController? { rt.topViewController }

    /// 提供 Home 指示条自动隐藏策略的子页面。
    open override var childForHomeIndicatorAutoHidden: UIViewController? { rt.topViewController }

    /// 提供系统边缘手势延迟策略的子页面。
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? { rt.topViewController }

    /// 当前内容页面要求的状态栏样式。
    open override var preferredStatusBarStyle: UIStatusBarStyle { rt.topViewController?.preferredStatusBarStyle ?? .default }

    /// 当前内容页面是否隐藏状态栏。
    open override var prefersStatusBarHidden: Bool { rt.topViewController?.prefersStatusBarHidden ?? false }

    /// 当前内容页面的状态栏更新动画。
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { rt.topViewController?.preferredStatusBarUpdateAnimation ?? .fade }

    /// 当前内容页面是否允许自动旋转。
    open override var shouldAutorotate: Bool { rt.topViewController?.shouldAutorotate ?? true }

    /// 当前内容页面支持的屏幕方向。
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { rt.topViewController?.supportedInterfaceOrientations ?? .all }

    /// 当前内容页面展示时优先使用的屏幕方向。
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { rt.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait }
}

private final class WeakBarItem {
    weak var item: UIBarButtonItem?

    init(_ item: UIBarButtonItem) { self.item = item }
}
