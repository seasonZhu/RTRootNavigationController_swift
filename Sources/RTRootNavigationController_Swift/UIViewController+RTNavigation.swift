import UIKit
import ObjectiveC

/// 页面可选的导航定制点，无需继承框架基类。
@MainActor public protocol RTNavigationCustomizing: AnyObject {
    var navigationBarClass: UINavigationBar.Type? { get }
    var animatedTransitioning: UIViewControllerAnimatedTransitioning? { get }
    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem?
    func nextSiblingController() -> UIViewController?
}

public extension RTNavigationCustomizing {
    var navigationBarClass: UINavigationBar.Type? { nil }
    var animatedTransitioning: UIViewControllerAnimatedTransitioning? { nil }
    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem? { nil }
    func nextSiblingController() -> UIViewController? { nil }
}

/// 自定义动画可同时提供交互控制器。
@MainActor public protocol RTViewControllerAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    var interactiveTransitioning: UIViewControllerInteractiveTransitioning? { get }
}

@MainActor private enum RTAssociationKeys {
    static var disablePop: UInt8 = 0
}

/// 导航扩展的命名空间，保留基础控制器的具体类型。
@MainActor public struct RTNavigation<Base: UIViewController> {
    public let base: Base

    public init(_ base: Base) { self.base = base }
}

/// 为控制器提供导航命名空间入口。
@MainActor public protocol RTNavigationCompatible: AnyObject {}

public extension RTNavigationCompatible where Self: UIViewController {
    var rt: RTNavigation<Self> { RTNavigation(self) }
}

extension UIViewController: RTNavigationCompatible {}

public extension RTNavigation {
    /// 显式设置后，不再根据隐藏导航栏或自定义左按钮自动推断。
    var isInteractivePopDisabled: Bool {
        get { (objc_getAssociatedObject(base, &RTAssociationKeys.disablePop) as? NSNumber)?.boolValue ?? false }
        nonmutating set { objc_setAssociatedObject(base, &RTAssociationKeys.disablePop, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 获取外层真实导航器，适用于每页导航容器及 TabBar 嵌套。
    var navigationController: RTRootNavigationController? {
        var current: UIViewController? = base
        while let controller = current {
            if let root = controller as? RTRootNavigationController { return root }
            current = controller.parent ?? controller.navigationController
        }
        return nil
    }
}

public extension RTNavigation where Base: RTRootNavigationController {
    /// 按导航顺序返回真实内容页面。
    var viewControllers: [UIViewController] { base.viewControllers.map(RTRootNavigationController.unwrap) }
    var topViewController: UIViewController? { base.topViewController.map(RTRootNavigationController.unwrap) }
    var visibleViewController: UIViewController? { base.visibleViewController.map(RTRootNavigationController.unwrap) }
}

extension UIViewController {
    var hasExplicitPopPreference: Bool {
        objc_getAssociatedObject(self, &RTAssociationKeys.disablePop) != nil
    }
    var navigationCustomization: RTNavigationCustomizing? { self as? RTNavigationCustomizing }
}
