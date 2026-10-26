import XCTest
import UIKit
@testable import RTRootNavigationController_Swift

@MainActor final class NavigationTests: XCTestCase {
    func testWrappingAndNavigationLookup() {
        let page = UIViewController()
        let root = RTRootNavigationController(rootViewController: page)
        root.loadViewIfNeeded()
        XCTAssertTrue(root.rt.topViewController === page)
        XCTAssertTrue(root.topViewController is RTContainerController)
        XCTAssertTrue(page.navigationController is RTContainerNavigationController)
        XCTAssertTrue(page.rt.navigationController === root)
    }
    func testNamespacePreservesBaseAndSharesPagePreference() {
        let page = CustomPage()
        let namespace: RTNavigation<CustomPage> = page.rt
        XCTAssertTrue(namespace.base === page)
        XCTAssertFalse(namespace.isInteractivePopDisabled)
        XCTAssertFalse(page.hasExplicitPopPreference)
        namespace.isInteractivePopDisabled = true
        XCTAssertTrue(page.rt.isInteractivePopDisabled)
        page.rt.isInteractivePopDisabled = false
        XCTAssertFalse(namespace.isInteractivePopDisabled)
        XCTAssertTrue(page.hasExplicitPopPreference)
    }
    func testInnerPushPopAndRealStack() {
        let first = UIViewController(), second = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        root.loadViewIfNeeded()
        first.navigationController?.pushViewController(second, animated: false)
        XCTAssertEqual(root.rt.viewControllers.count, 2)
        XCTAssertTrue(first.navigationController?.viewControllers.last === second)
        XCTAssertTrue(second.navigationController?.popViewController(animated: false) === second)
        XCTAssertTrue(root.rt.topViewController === first)
    }
    func testSetRemoveAndPopToIdentity() {
        let first = UIViewController(), second = UIViewController(), third = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        root.setViewControllers([first, second, third], animated: false)
        let popped = root.popToViewController(second, animated: false)
        XCTAssertEqual(popped?.count, 1)
        XCTAssertTrue(popped?.first === third)
        root.removeViewController(second)
        XCTAssertTrue(root.rt.topViewController === first)
        root.removeViewController(first)
        XCTAssertEqual(root.rt.viewControllers.count, 1)
    }
    func testNonanimatedCompletionsAndNoOp() {
        let first = UIViewController(), second = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        var results: [Bool] = []
        root.pushViewController(second, animated: false) { results.append($0) }
        root.popToRootViewController(animated: false) { results.append($0) }
        root.popViewController(animated: false) { results.append($0) }
        XCTAssertEqual(results, [true, true, true])
    }
    func testBackCallbackOnlyHandlesButtonAction() {
        let first = UIViewController(), second = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        root.pushViewController(second, animated: false)
        var count = 0
        root.onBackCallback = { count += 1 }
        root.onBack(nil)
        XCTAssertEqual(count, 1)
        XCTAssertTrue(root.rt.topViewController === second)
        root.popViewController(animated: false)
        XCTAssertEqual(count, 1)
        XCTAssertTrue(root.rt.topViewController === first)
    }
    func testCustomNavigationAndBackItem() {
        let first = UIViewController(), second = CustomPage()
        let root = RTRootNavigationController(rootViewController: first)
        root.pushViewController(second, animated: false)
        XCTAssertTrue(second.navigationController?.navigationBar is CustomBar)
        XCTAssertEqual(second.navigationItem.leftBarButtonItem?.title, "自定义")
    }
    func testExplicitPopPreferenceOverridesHiddenBarDefault() {
        let first = UIViewController(), second = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        root.loadViewIfNeeded()
        root.pushViewController(second, animated: false)
        second.navigationController?.setNavigationBarHidden(true, animated: false)
        guard let gesture = root.interactivePopGestureRecognizer else { return XCTFail("缺少返回手势") }
        XCTAssertFalse(root.gestureRecognizerShouldBegin(gesture))
        second.rt.isInteractivePopDisabled = false
        XCTAssertTrue(root.gestureRecognizerShouldBegin(gesture))
        second.rt.isInteractivePopDisabled = true
        XCTAssertFalse(root.gestureRecognizerShouldBegin(gesture))
    }
    func testAppearanceIsIndependentByDefaultAndInheritedExplicitly() {
        let first = UIViewController(), second = UIViewController()
        let own = UINavigationBarAppearance()
        own.backgroundColor = .systemBlue
        second.navigationItem.standardAppearance = own
        let shared = UINavigationBarAppearance()
        shared.backgroundColor = .systemRed
        first.navigationItem.standardAppearance = shared
        let root = RTRootNavigationController(rootViewController: first)
        root.pushViewController(second, animated: false)
        guard let inner = second.navigationController as? RTContainerNavigationController else { return XCTFail() }
        root.applyAppearance(to: inner)
        XCTAssertEqual(second.navigationItem.standardAppearance?.backgroundColor, .systemBlue)
        root.transferNavigationBarAttributes = true
        root.applyAppearance(to: inner)
        XCTAssertEqual(second.navigationItem.standardAppearance?.backgroundColor, .systemRed)
        XCTAssertFalse(second.navigationItem.standardAppearance === first.navigationItem.standardAppearance)
    }
    func testSystemBackPlaceholderAndButtonExclusion() {
        let first = UIViewController(), second = UIViewController()
        first.title = "上一页"
        let root = RTRootNavigationController(rootViewController: first)
        root.useSystemBackBarButtonItem = true
        root.pushViewController(second, animated: false)
        guard let container = root.topViewController as? RTContainerController else { return XCTFail() }
        XCTAssertNil(second.navigationItem.leftBarButtonItem)
        container.loadViewIfNeeded()
        container.containerNavigationController?.loadViewIfNeeded()
        XCTAssertEqual(container.containerNavigationController?.navigationBar.backItem?.title, "上一页")
    }
    func testNoWrappingTabStructure() {
        let page = UIViewController()
        let inner = RTContainerNavigationController(rootViewController: page)
        let tab = UITabBarController()
        tab.viewControllers = [inner]
        let root = RTRootNavigationController(rootViewControllerNoWrapping: tab)
        XCTAssertNil((root.topViewController as? RTContainerController)?.containerNavigationController)
        XCTAssertTrue(page.rt.navigationController === root)
        inner.pushViewController(UIViewController(), animated: false)
        XCTAssertEqual(root.rt.viewControllers.count, 2)
    }
    func testDelegateReceivesContentControllers() {
        let page = UIViewController()
        let root = RTRootNavigationController(rootViewController: page)
        let delegate = RecordingDelegate()
        root.delegate = delegate
        guard let wrapper = root.topViewController else { return XCTFail() }
        root.navigationController(root, willShow: wrapper, animated: false)
        root.navigationController(root, didShow: wrapper, animated: false)
        XCTAssertTrue(delegate.willShow === page)
        XCTAssertTrue(delegate.didShow === page)
    }
    func testCompletionRunsOnceAfterDidShow() {
        let first = UIViewController(), second = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        root.loadViewIfNeeded()
        // 在未挂载窗口时，非动画操作仍须精确完成一次。
        var calls = 0
        root.pushViewController(second, animated: false) { finished in
            XCTAssertTrue(finished)
            calls += 1
        }
        if let shown = root.topViewController { root.navigationController(root, didShow: shown, animated: false) }
        XCTAssertEqual(calls, 1)
    }
    func testInteractionCompletionThresholds() {
        XCTAssertFalse(RTInteractionDecision.shouldFinish(progress: 0.2, velocity: 0))
        XCTAssertTrue(RTInteractionDecision.shouldFinish(progress: 0.7, velocity: 0))
        XCTAssertTrue(RTInteractionDecision.shouldFinish(progress: 0.1, velocity: 700))
        XCTAssertFalse(RTInteractionDecision.shouldFinish(progress: 0.8, velocity: -700))
    }
    func testChangingStackRefreshesSystemBackTitle() {
        let first = UIViewController(), middle = UIViewController(), last = UIViewController()
        first.title = "第一页"
        middle.title = "中间页"
        let root = RTRootNavigationController(rootViewController: first)
        root.useSystemBackBarButtonItem = true
        root.setViewControllers([first, middle, last], animated: false)
        root.removeViewController(middle)
        guard let inner = last.navigationController else { return XCTFail() }
        inner.loadViewIfNeeded()
        XCTAssertEqual(inner.navigationBar.backItem?.title, "第一页")
    }
    func testCustomAnimationAndInteractionForwarding() {
        let page = AnimatedPage()
        let root = RTRootNavigationController(rootViewController: UIViewController())
        let wrapped = RTContainerController(content: page)
        guard let from = root.topViewController else { return XCTFail() }
        let animation = root.navigationController(root, animationControllerFor: .push, from: from, to: wrapped)
        XCTAssertTrue(animation === page.animator)
        XCTAssertTrue(root.navigationController(root, interactionControllerFor: page.animator) === page.animator.interaction)
    }
    func testSlideAnimatorCompletesAndCancels() {
        for cancelled in [false, true] {
            let completed = expectation(description: cancelled ? "取消" : "完成")
            let context = TransitionContext(cancelled: cancelled) { finished in
                XCTAssertEqual(finished, !cancelled)
                completed.fulfill()
            }
            RTSlideAnimator(direction: -1).animateTransition(using: context)
            wait(for: [completed], timeout: 2)
            XCTAssertEqual(context.from.view.transform, .identity)
            XCTAssertEqual(context.to.view.transform, .identity)
            if cancelled { XCTAssertNil(context.to.view.superview) }
        }
    }
    func testReplacementCallbackReentryKeepsNewestOperation() {
        let root = DeferredNavigationController(rootViewController: UIViewController())
        let first = UIViewController(), replaced = UIViewController(), newest = UIViewController()
        var results: [String] = []
        root.beginDeferredTransition()
        root.pushViewController(first, animated: true) { finished in
            results.append("first:\(finished)")
            if !finished {
                root.pushViewController(newest, animated: true) { results.append("newest:\($0)") }
            }
        }
        root.pushViewController(replaced, animated: true) { results.append("replaced:\($0)") }
        XCTAssertEqual(root.requests.map(ObjectIdentifier.init), [first, newest].map(ObjectIdentifier.init))
        XCTAssertEqual(results, ["first:false", "replaced:false"])
        root.navigationController(root, didShow: newest, animated: true)
        XCTAssertEqual(results, ["first:false", "replaced:false", "newest:true"])
    }
    func testSynchronousDidShowCannotFinishNewOperation() {
        let root = DeferredNavigationController(rootViewController: UIViewController())
        let first = UIViewController(), newest = UIViewController()
        var results: [String] = []
        root.didRequest = { controller in
            if controller === first { root.navigationController(root, didShow: first, animated: false) }
        }
        root.pushViewController(first, animated: false) { finished in
            results.append("first:\(finished)")
            root.beginDeferredTransition()
            root.pushViewController(newest, animated: true) { results.append("newest:\($0)") }
        }
        XCTAssertEqual(results, ["first:true"])
        root.navigationController(root, didShow: newest, animated: true)
        XCTAssertEqual(results, ["first:true", "newest:true"])
        root.didRequest = nil
    }
    func testCancelledNavigationCompletionRunsOnce() {
        let first = UIViewController(), next = UIViewController()
        let root = DeferredNavigationController(rootViewController: first)
        var results: [Bool] = []
        root.beginDeferredTransition()
        root.pushViewController(next, animated: true) { results.append($0) }
        root.navigationController(root, didShow: first, animated: true)
        root.navigationController(root, didShow: first, animated: true)
        XCTAssertEqual(results, [false])
    }
    func testClassNameUsesRuntimeType() {
        let page: UIViewController = CustomPage()
        XCTAssertEqual(page.rt.className, "CustomPage")
        XCTAssertEqual(page.rt.className, String(describing: type(of: page)))
    }

    func testRemoveByNamesMatchesAllInstancesAndPreservesNonemptyStack() {
        let first = UIViewController(), second = CustomPage(), third = CustomPage()
        let root = RTRootNavigationController(rootViewController: first)
        root.setViewControllers([first, second, third], animated: false)
        root.removeViewControllerByClassNames([])
        root.removeViewControllerByClassNames(["Unknown", "custompage"])
        XCTAssertEqual(root.rt.viewControllers.count, 3)
        root.removeViewControllerByClassNames(["UIViewController", "CustomPage"])
        XCTAssertEqual(root.rt.viewControllers.count, 3)
        root.removeViewControllerByClassNames([second.rt.className, second.rt.className])
        XCTAssertEqual(root.rt.viewControllers.map(ObjectIdentifier.init), [ObjectIdentifier(first)])
    }

    func testPushRemovesOnlyCurrentInstanceAndKeepsSameClassTarget() {
        let first = CustomPage(), current = CustomPage(), next = CustomPage()
        let root = RTRootNavigationController(rootViewController: first)
        root.pushViewController(current, animated: false)
        root.pushViewController(next, animated: false, removeCurrentViewController: true)
        XCTAssertEqual(root.rt.viewControllers.map(ObjectIdentifier.init), [first, next].map(ObjectIdentifier.init))
    }

    func testPushCleanupCanReplaceRootAndRemoveNamedPages() {
        let first = UIViewController(), current = CustomPage(), next = CustomPage()
        let root = RTRootNavigationController(rootViewController: first)
        root.pushViewController(current, animated: false)
        root.pushViewController(next, animated: false,
                                removeViewControllerClassNameList: [first.rt.className, next.rt.className],
                                removeCurrentViewController: false)
        XCTAssertEqual(root.rt.viewControllers.map(ObjectIdentifier.init), [ObjectIdentifier(next)])
        let replacement = CustomPage()
        root.pushViewController(replacement, animated: false, removeCurrentViewController: true)
        XCTAssertTrue(root.rt.viewControllers.first === replacement)
        XCTAssertEqual(root.rt.viewControllers.count, 1)
    }

    func testPushWithoutRemovalKeepsOldStack() {
        let first = UIViewController(), second = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        root.pushViewController(second, animated: false, removeCurrentViewController: false)
        XCTAssertEqual(root.rt.viewControllers.map(ObjectIdentifier.init), [first, second].map(ObjectIdentifier.init))
    }

    func testClassNamePopFindsFirstMatchAndCompletesOnce() {
        let first = CustomPage(), second = CustomPage(), last = UIViewController()
        let root = RTRootNavigationController(rootViewController: first)
        root.setViewControllers([first, second, last], animated: false)
        var results: [Bool] = []
        root.popToViewController(className: first.rt.className, animated: false) { results.append($0) }
        XCTAssertTrue(root.rt.topViewController === first)
        root.popToViewController(className: first.rt.className, animated: false) { results.append($0) }
        root.popToViewController(className: "Unknown", animated: false) { results.append($0) }
        if let shown = root.topViewController { root.navigationController(root, didShow: shown, animated: false) }
        XCTAssertEqual(results, [true, true, true])
    }

    func testClassNamePopFallbackWithoutCompletion() {
        let first = UIViewController(), second = CustomPage()
        let root = RTRootNavigationController(rootViewController: first)
        root.pushViewController(second, animated: false)
        root.popToViewController(className: "Unknown", animated: false)
        XCTAssertTrue(root.rt.topViewController === first)
    }

    func testNamedRemovalForwardsAnimationAndSkipsNoOpUpdates() {
        let first = UIViewController(), second = CustomPage()
        let root = DeferredNavigationController(rootViewController: first)
        root.recordedStack = [first, second]
        root.removeViewControllerByClassNames(["Unknown"], animated: true)
        XCTAssertTrue(root.stackUpdateAnimations.isEmpty)
        root.removeViewControllerByClassNames([second.rt.className], animated: true)
        XCTAssertEqual(root.stackUpdateAnimations, [true])
        XCTAssertTrue(root.rt.topViewController === first)
    }

    func testClassNamePopPassesAnimationToBothPaths() {
        for animated in [false, true] {
            let first = UIViewController(), second = CustomPage()
            let root = DeferredNavigationController(rootViewController: first)
            root.setViewControllers([first, second], animated: false)
            root.popToViewController(className: "Unknown", animated: animated)
            XCTAssertEqual(root.popAnimations.last, animated)
            root.setViewControllers([first, second], animated: false)
            root.popToViewController(className: first.rt.className, animated: animated) { _ in }
            XCTAssertEqual(root.popToAnimations.last, animated)
        }
    }

    func testDeferredPushCleansOnceOnlyAfterSuccess() {
        let first = UIViewController(), current = CustomPage(), next = CustomPage()
        let root = DeferredNavigationController(rootViewController: first)
        root.recordedStack = [first, current]
        root.beginDeferredTransition()
        root.pushViewController(next, animated: true, removeCurrentViewController: true)
        XCTAssertEqual(root.rt.viewControllers.count, 3)
        XCTAssertTrue(root.stackUpdateAnimations.isEmpty)
        root.navigationController(root, didShow: next, animated: true)
        root.navigationController(root, didShow: next, animated: true)
        XCTAssertEqual(root.rt.viewControllers.map(ObjectIdentifier.init), [first, next].map(ObjectIdentifier.init))
        XCTAssertEqual(root.stackUpdateAnimations, [false])
    }

    func testCleanupOnlyRemovesInstancesRecordedBeforePush() {
        let oldPage = CustomPage(), laterPage = CustomPage(), next = UIViewController()
        let root = DeferredNavigationController(rootViewController: oldPage)
        root.recordedStack = [oldPage]
        root.beginDeferredTransition()
        root.pushViewController(next, animated: true,
                                removeViewControllerClassNameList: [oldPage.rt.className],
                                removeCurrentViewController: false)
        root.recordedStack = [oldPage, laterPage, next]
        root.navigationController(root, didShow: next, animated: true)
        XCTAssertEqual(root.rt.viewControllers.map(ObjectIdentifier.init), [laterPage, next].map(ObjectIdentifier.init))
    }

    func testCancelledCleanupDoesNotRemoveOldPage() {
        let first = UIViewController(), next = CustomPage()
        let root = DeferredNavigationController(rootViewController: first)
        root.recordedStack = [first]
        root.beginDeferredTransition()
        root.pushViewController(next, animated: true, removeCurrentViewController: true)
        root.recordedStack = [first]
        root.navigationController(root, didShow: first, animated: true)
        XCTAssertTrue(root.rt.topViewController === first)
        XCTAssertTrue(root.stackUpdateAnimations.isEmpty)
    }

    func testReplacedCleanupDoesNotRemoveOldPage() {
        let first = UIViewController(), next = CustomPage(), newest = UIViewController()
        let root = DeferredNavigationController(rootViewController: first)
        root.recordedStack = [first]
        root.beginDeferredTransition()
        root.pushViewController(next, animated: true, removeCurrentViewController: true)
        var results: [Bool] = []
        root.pushViewController(newest, animated: true) { results.append($0) }
        root.navigationController(root, didShow: newest, animated: true)
        XCTAssertEqual(root.rt.viewControllers.count, 3)
        XCTAssertTrue(root.stackUpdateAnimations.isEmpty)
        XCTAssertEqual(results, [true])
    }

    func testLaterNavigationPreventsStaleCleanup() {
        let first = UIViewController(), next = CustomPage(), newest = UIViewController()
        let root = DeferredNavigationController(rootViewController: first)
        root.recordedStack = [first]
        root.beginDeferredTransition()
        root.pushViewController(next, animated: true, removeCurrentViewController: true)
        // 无完成回调的后续 Push 不会替换回调槽，清理仍须检查真实栈顶。
        root.pushViewController(newest, animated: true)
        root.navigationController(root, didShow: next, animated: true)
        XCTAssertEqual(root.rt.viewControllers.count, 3)
        XCTAssertTrue(root.stackUpdateAnimations.isEmpty)
    }

    func testContainersReleaseAfterRemoval() {
        let root = RTRootNavigationController(rootViewController: UIViewController())
        weak var released: UIViewController?
        autoreleasepool {
            let page = UIViewController()
            released = page
            root.pushViewController(page, animated: false)
            root.popViewController(animated: false)
        }
        XCTAssertNil(released)
    }
}

private final class CustomBar: UINavigationBar {}
private final class CustomPage: UIViewController, RTNavigationCustomizing {
    var navigationBarClass: UINavigationBar.Type? { CustomBar.self }
    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem? {
        UIBarButtonItem(title: "自定义", style: .plain, target: target, action: action)
    }
}
@MainActor private final class RecordingDelegate: NSObject, UINavigationControllerDelegate {
    weak var willShow: UIViewController?
    weak var didShow: UIViewController?
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) { willShow = viewController }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) { didShow = viewController }
}

private final class AnimatedPage: UIViewController, RTNavigationCustomizing {
    let animator = InteractiveAnimator()
    var animatedTransitioning: UIViewControllerAnimatedTransitioning? { animator }
}
private final class InteractiveAnimator: NSObject, RTViewControllerAnimatedTransitioning {
    let interaction = UIPercentDrivenInteractiveTransition()
    var interactiveTransitioning: UIViewControllerInteractiveTransitioning? { interaction }
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0 }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) { transitionContext.completeTransition(!transitionContext.transitionWasCancelled) }
}
@MainActor private final class TransitionContext: NSObject, UIViewControllerContextTransitioning {
    let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
    let from = UIViewController(), to = UIViewController()
    let transitionWasCancelled: Bool
    let isAnimated = true
    let isInteractive = true
    let presentationStyle = UIModalPresentationStyle.none
    let targetTransform = CGAffineTransform.identity
    private let completion: (Bool) -> Void
    init(cancelled: Bool, completion: @escaping (Bool) -> Void) {
        transitionWasCancelled = cancelled
        self.completion = completion
        super.init()
        from.view.frame = containerView.bounds
        containerView.addSubview(from.view)
    }
    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
    func pauseInteractiveTransition() {}
    func completeTransition(_ didComplete: Bool) { completion(didComplete) }
    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? { key == .from ? from : to }
    func view(forKey key: UITransitionContextViewKey) -> UIView? { key == .from ? from.view : to.view }
    func initialFrame(for vc: UIViewController) -> CGRect { containerView.bounds }
    func finalFrame(for vc: UIViewController) -> CGRect { containerView.bounds }
}

/// 仅记录导航请求，由测试经公开代理事件控制结束顺序，不依赖 UIKit 动画调度。
private final class DeferredNavigationController: RTRootNavigationController {
    var recordedStack: [UIViewController]?
    var stackUpdateAnimations: [Bool] = []
    var popAnimations: [Bool] = []
    var popToAnimations: [Bool] = []

    override var viewControllers: [UIViewController] {
        get { recordedStack ?? super.viewControllers }
        set { super.viewControllers = newValue }
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if recordedStack != nil {
            recordedStack = viewControllers
            stackUpdateAnimations.append(animated)
        } else {
            super.setViewControllers(viewControllers, animated: animated)
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        popAnimations.append(animated)
        return super.popViewController(animated: false)
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        popToAnimations.append(animated)
        return super.popToViewController(viewController, animated: false)
    }

    var requests: [UIViewController] = []
    var didRequest: ((UIViewController) -> Void)?
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        recordedStack?.append(viewController)
        requests.append(viewController)
        didRequest?(viewController)
    }
    func beginDeferredTransition() {
        guard let current = topViewController else { return }
        navigationController(self, willShow: current, animated: true)
    }
}
