import UIKit

/// 为每个内容页面提供独立导航栏，外层负责真实导航栈和转场。
open class RTRootNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    public var useSystemBackBarButtonItem = false
    public var transferNavigationBarAttributes = false
    /// 仅接管框架生成的返回按钮。设置后不会自动 pop。
    public var onBackCallback: (() -> Void)?
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


    public override init(rootViewController: UIViewController) {
        super.init(navigationBarClass: nil, toolbarClass: nil)
        super.setViewControllers([wrap(rootViewController, previous: nil)], animated: false)
    }
    public init(rootViewControllerNoWrapping rootViewController: UIViewController) {
        super.init(navigationBarClass: nil, toolbarClass: nil)
        super.setViewControllers([RTContainerController(content: rootViewController, wrapping: false)], animated: false)
    }
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }
    public required init?(coder: NSCoder) { super.init(coder: coder) }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setViewControllers(super.viewControllers, animated: false)
    }

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

    /// 外层导航栏始终隐藏；页面通过自己的 navigationController 控制独立导航栏。
    open override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {}

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

    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        precondition(!rt.viewControllers.contains(where: { $0 === viewController }), "同一页面不能重复入栈")
        super.pushViewController(wrap(viewController, previous: rt.topViewController), animated: animated)
        if !animated { updateVisibleState() }
    }

    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        let contents = viewControllers.map(Self.unwrap)
        precondition(Set(contents.map(ObjectIdentifier.init)).count == contents.count, "导航栈不能包含重复页面")
        let wrapped = viewControllers.enumerated().map { index, controller in
            wrap(controller, previous: index > 0 ? contents[index - 1] : nil)
        }
        super.setViewControllers(wrapped, animated: animated)
        if !animated { updateVisibleState() }
    }

    @discardableResult open override func popViewController(animated: Bool) -> UIViewController? {
        let popped = super.popViewController(animated: animated).map(Self.unwrap)
        if !animated { updateVisibleState() }
        return popped
    }
    @discardableResult open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        guard let target = super.viewControllers.first(where: { $0 === viewController || Self.unwrap($0) === viewController }) else { return nil }
        let popped = super.popToViewController(target, animated: animated)?.map(Self.unwrap)
        if !animated { updateVisibleState() }
        return popped
    }
    @discardableResult open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        guard let root = rt.viewControllers.first else { return nil }
        return popToViewController(root, animated: animated)
    }
    public func removeViewController(_ controller: UIViewController, animated: Bool = false) {
        let stack = super.viewControllers.filter { $0 !== controller && Self.unwrap($0) !== controller }
        guard stack.count != super.viewControllers.count, !stack.isEmpty else { return }
        setViewControllers(stack, animated: animated)
    }

    public func pushViewController(_ controller: UIViewController, animated: Bool, completion: @escaping (Bool) -> Void) {
        guard let generation = beginCompletion(completion) else { return }
        completionTarget = controller
        pushViewController(controller, animated: animated)
        finishWithoutTransitionIfNeeded(animated: animated, generation: generation)
    }
    @discardableResult public func popViewController(animated: Bool, completion: @escaping (Bool) -> Void) -> UIViewController? {
        guard let generation = beginCompletion(completion) else { return nil }
        completionTarget = rt.viewControllers.dropLast().last
        let result = popViewController(animated: animated)
        finishWithoutTransitionIfNeeded(animated: animated && result != nil, generation: generation)
        return result
    }
    @discardableResult public func popToViewController(_ controller: UIViewController, animated: Bool, completion: @escaping (Bool) -> Void) -> [UIViewController]? {
        guard let generation = beginCompletion(completion) else { return nil }
        completionTarget = controller
        let result = popToViewController(controller, animated: animated)
        finishWithoutTransitionIfNeeded(animated: animated && !(result?.isEmpty ?? true), generation: generation)
        return result
    }
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

    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        isTransitioning = true
        let content = Self.unwrap(viewController)
        if let container = viewController as? RTContainerController, let inner = container.containerNavigationController { applyAppearance(to: inner) }
        forwardedDelegate?.navigationController?(self, willShow: content, animated: animated)
    }
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        isTransitioning = false
        updateVisibleState()
        resolveCompletion(completionTarget == nil || completionTarget === Self.unwrap(viewController))
        forwardedDelegate?.navigationController?(self, didShow: Self.unwrap(viewController), animated: animated)
    }
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let interactionAnimator { return interactionAnimator }
        let from = Self.unwrap(fromVC), to = Self.unwrap(toVC)
        if let external = forwardedDelegate?.navigationController?(self, animationControllerFor: operation, from: from, to: to) { return external }
        return (operation == .push ? to : from).navigationCustomization?.animatedTransitioning
    }
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let pushInteraction { return pushInteraction }
        return forwardedDelegate?.navigationController?(self, interactionControllerFor: animationController)
            ?? (animationController as? RTViewControllerAnimatedTransitioning)?.interactiveTransitioning
    }
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        forwardedDelegate?.navigationControllerSupportedInterfaceOrientations?(self) ?? supportedInterfaceOrientations
    }
    public func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        forwardedDelegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(self) ?? preferredInterfaceOrientationForPresentation
    }

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

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer === interactivePopGestureRecognizer
    }
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

    open override var childForStatusBarStyle: UIViewController? { rt.topViewController }
    open override var childForStatusBarHidden: UIViewController? { rt.topViewController }
    open override var childForHomeIndicatorAutoHidden: UIViewController? { rt.topViewController }
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? { rt.topViewController }
    open override var preferredStatusBarStyle: UIStatusBarStyle { rt.topViewController?.preferredStatusBarStyle ?? .default }
    open override var prefersStatusBarHidden: Bool { rt.topViewController?.prefersStatusBarHidden ?? false }
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { rt.topViewController?.preferredStatusBarUpdateAnimation ?? .fade }
    open override var shouldAutorotate: Bool { rt.topViewController?.shouldAutorotate ?? true }
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { rt.topViewController?.supportedInterfaceOrientations ?? .all }
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { rt.topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait }
}

private final class WeakBarItem {
    weak var item: UIBarButtonItem?
    init(_ item: UIBarButtonItem) { self.item = item }
}
