import UIKit

/// 自定义动画可同时提供交互控制器。
@MainActor public protocol RTViewControllerAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    /// 自定义动画关联的交互控制器；返回 `nil` 表示不使用交互控制。
    /// 外部导航代理提供的交互控制器优先，内建交互 Push 使用框架自己的控制器。
    var interactiveTransitioning: UIViewControllerInteractiveTransitioning? { get }
}
