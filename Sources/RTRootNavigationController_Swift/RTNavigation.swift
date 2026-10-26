import UIKit
import ObjectiveC

/// 导航扩展的命名空间，保留基础控制器的具体类型。
@MainActor public struct RTNavigation<Base: UIViewController> {
    /// 命名空间包装的原始控制器，保留调用方的具体类型。
    public let base: Base

    /// 创建控制器的导航命名空间包装。
    /// - Parameter base: 需要访问导航扩展的原始控制器。
    public init(_ base: Base) { self.base = base }
}

public extension RTNavigation {
    /// 基础控制器的运行时类型名称，不包含模块名，区分大小写。
    /// 使用真实实例类型，即使通过父类引用访问也返回子类名称；不同模块的同名类会匹配为相同名称。
    var className: String { String(describing: type(of: base)) }

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
