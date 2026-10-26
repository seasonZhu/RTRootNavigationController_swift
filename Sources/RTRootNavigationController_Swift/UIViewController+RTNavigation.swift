import UIKit
import ObjectiveC

/// 页面可选的导航定制点，无需继承框架基类。
@MainActor public protocol RTNavigationCustomizing: AnyObject {
    /// 页面导航栏的类型，默认返回 `nil`，使用 UIKit 标准导航栏。
    /// 框架创建页面容器时读取；需要自定义类型时应在页面入栈前确定。
    var navigationBarClass: UINavigationBar.Type? { get }

    /// 页面自定义转场动画，默认返回 `nil`，使用 UIKit 默认动画。
    /// Push 读取目标页面，Pop 读取来源页面；外部代理返回的动画优先，内建交互 Push 动画优先级最高。
    var animatedTransitioning: UIViewControllerAnimatedTransitioning? { get }

    /// 创建框架返回按钮；默认返回 `nil`，由框架生成文字返回按钮。
    /// 仅在非根页面、未启用系统返回按钮且没有业务左按钮时调用。
    /// - Parameters:
    ///   - target: 按钮应绑定的目标对象。
    ///   - action: 按钮应触发的返回方法选择器。
    /// - Returns: 绑定给定 target/action 的按钮，或 `nil` 使用默认按钮。
    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem?

    /// 为边缘交互 Push 提供下一页面，默认返回 `nil`，不启动手势。
    /// 在手势开始判定时调用，应返回未在导航栈中的页面；避免在此执行不可撤销的业务操作。
    /// - Returns: 下一页面，或 `nil` 表示当前页面不支持交互 Push。
    func nextSiblingController() -> UIViewController?
}

public extension RTNavigationCustomizing {
    /// 页面导航栏的类型，默认返回 `nil`，使用 UIKit 标准导航栏。
    /// 框架创建页面容器时读取；需要自定义类型时应在页面入栈前确定。
    var navigationBarClass: UINavigationBar.Type? { nil }

    /// 页面自定义转场动画，默认返回 `nil`，使用 UIKit 默认动画。
    /// Push 读取目标页面，Pop 读取来源页面；外部代理返回的动画优先，内建交互 Push 动画优先级最高。
    var animatedTransitioning: UIViewControllerAnimatedTransitioning? { nil }

    /// 创建框架返回按钮；默认返回 `nil`，由框架生成文字返回按钮。
    /// 仅在非根页面、未启用系统返回按钮且没有业务左按钮时调用。
    /// - Parameters:
    ///   - target: 按钮应绑定的目标对象。
    ///   - action: 按钮应触发的返回方法选择器。
    /// - Returns: 绑定给定 target/action 的按钮，或 `nil` 使用默认按钮。
    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem? { nil }

    /// 为边缘交互 Push 提供下一页面，默认返回 `nil`，不启动手势。
    /// 在手势开始判定时调用，应返回未在导航栈中的页面；避免在此执行不可撤销的业务操作。
    /// - Returns: 下一页面，或 `nil` 表示当前页面不支持交互 Push。
    func nextSiblingController() -> UIViewController? { nil }
}

/// 自定义动画可同时提供交互控制器。
@MainActor public protocol RTViewControllerAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    /// 自定义动画关联的交互控制器；返回 `nil` 表示不使用交互控制。
    /// 外部导航代理提供的交互控制器优先，内建交互 Push 使用框架自己的控制器。
    var interactiveTransitioning: UIViewControllerInteractiveTransitioning? { get }
}

@MainActor private enum RTAssociationKeys {
    static var disablePop: UInt8 = 0
}

/// 导航扩展的命名空间，保留基础控制器的具体类型。
@MainActor public struct RTNavigation<Base: UIViewController> {
    /// 命名空间包装的原始控制器，保留调用方的具体类型。
    public let base: Base

    /// 创建控制器的导航命名空间包装。
    /// - Parameter base: 需要访问导航扩展的原始控制器。
    public init(_ base: Base) { self.base = base }
}

/// 为控制器提供导航命名空间入口。
@MainActor public protocol RTNavigationCompatible: AnyObject {}

public extension RTNavigationCompatible where Self: UIViewController {
    /// 返回当前控制器的导航命名空间，用于读取根导航器及配置交互返回。
    var rt: RTNavigation<Self> { RTNavigation(self) }
}

extension UIViewController: RTNavigationCompatible {}

public extension RTNavigation {
    /// 是否显式禁用当前页面的边缘交互返回。
    /// 未设置时读取为 `false`，框架仍会根据隐藏导航栏和业务左按钮自动判定。
    /// 一旦赋值（包括 `false`），显式值优先于自动判定；不影响按钮返回和程序化 pop。
    var isInteractivePopDisabled: Bool {
        get { (objc_getAssociatedObject(base, &RTAssociationKeys.disablePop) as? NSNumber)?.boolValue ?? false }
        nonmutating set { objc_setAssociatedObject(base, &RTAssociationKeys.disablePop, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 沿父控制器和导航容器查找外层根导航器。
    /// 适用于内容页面、页面导航器及 TabBar 嵌套；尚未加入根导航层级时返回 `nil`。
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
    /// 按入栈顺序返回真实内容页面数组。
    var viewControllers: [UIViewController] { base.viewControllers.map(RTRootNavigationController.unwrap) }

    /// 返回栈顶的真实内容页面，空栈时为 `nil`。
    var topViewController: UIViewController? { base.topViewController.map(RTRootNavigationController.unwrap) }

    /// 解包 UIKit 当前可见控制器；若展示模态页面，结果也可能是该模态页面。
    var visibleViewController: UIViewController? { base.visibleViewController.map(RTRootNavigationController.unwrap) }
}

extension UIViewController {
    var hasExplicitPopPreference: Bool {
        objc_getAssociatedObject(self, &RTAssociationKeys.disablePop) != nil
    }
    var navigationCustomization: RTNavigationCustomizing? { self as? RTNavigationCustomizing }
}
