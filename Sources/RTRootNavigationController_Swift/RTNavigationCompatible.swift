import UIKit

/// 为控制器提供导航命名空间入口。
@MainActor public protocol RTNavigationCompatible: AnyObject {}

public extension RTNavigationCompatible where Self: UIViewController {
    /// 返回当前控制器的导航命名空间，用于读取根导航器及配置交互返回。
    var rt: RTNavigation<Self> { RTNavigation(self) }
}
