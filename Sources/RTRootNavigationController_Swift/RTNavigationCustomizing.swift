import UIKit

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
