//
//  UIViewController+RTRootNavigationController.swift
//  Pods-RTRootNavigationController_Swift_Example
//
//  Created by xujie on 2018/3/15.
//

import UIKit

@objc protocol RTNavigationComponentCustomizable {
    
    func rt_customBackItemWithTarget(target: Any, action: Selector) -> UIBarButtonItem?
    
    func rt_navigationBarClass() -> AnyClass?
    
}

// TODO:  handel access control problems

extension UIViewController {
    private struct RuntimeKey {
        static var disableInteractivePopKey = "disableInteractivePop"
    }
    
    public var rt_disableInteractivePop: Bool {
        
        set{
            objc_setAssociatedObject(self, &RuntimeKey.disableInteractivePopKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get{
            return objc_getAssociatedObject(self, &RuntimeKey.disableInteractivePopKey) as? Bool ?? false
        }

    }
    
    public var rt_navigationController: RTRootNavigationController? {
        var vc: UIViewController? = self
        while vc != nil && !(vc is RTRootNavigationController) {
            vc = vc?.navigationController
        }
        return vc as? RTRootNavigationController
    }
}

extension UIViewController: RTNavigationComponentCustomizable {
    open func rt_customBackItemWithTarget(target: Any, action: Selector) -> UIBarButtonItem? {
        return nil
    }
    
    open func rt_navigationBarClass() -> AnyClass? {
        return nil
    }
}
