//
//  UIViewController+RTCompatible.swift
//
//
//  Created by season on 2019/11/8.
//

import UIKit

extension UIViewController {
    private struct RuntimeKey {
        static var disableInteractivePopKey = "disableInteractivePop"
    }
    
    fileprivate var disableInteractivePop: Bool {
        
        set{
            objc_setAssociatedObject(self, &RuntimeKey.disableInteractivePopKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get{
            let boolean = objc_getAssociatedObject(self, &RuntimeKey.disableInteractivePopKey) as? Bool ?? false
            let info = String(describing: type(of: self)) + " disableInteractivePop:\(boolean)"
            print(info)
            return boolean
        }

    }
}

extension RTCategory where Base: UIViewController {
    
    public var disableInteractivePop: Bool {
        
        set{
            base.disableInteractivePop = newValue
        }
        
        get{
            return base.disableInteractivePop
        }

    }
    
    public var navigationController: RTRootNavigationController? {
        var vc: UIViewController? = base
        while vc != nil && !(vc is RTRootNavigationController) {
            vc = vc?.navigationController
        }
        return vc as? RTRootNavigationController
    }
}

extension UIViewController: RTCompatible {}

extension UIViewController: RTNavigationComponentCustomizable {
    open func customBackItemWithTarget(target: Any, action: Selector) -> UIBarButtonItem? {
        return nil
    }
    
    open func customNavigationBar() -> AnyClass? {
        return nil
    }
    
    open func customToolbarClass() -> AnyClass? {
        return nil
    }
}
