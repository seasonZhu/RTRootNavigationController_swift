//
//  RTContainerNavigationController.swift
//  
//
//  Created by season on 2019/11/11.
//

import UIKit

/// RTContainerNavigationController
class RTContainerNavigationController: UINavigationController {
    
    override init(rootViewController: UIViewController) {
        super.init(navigationBarClass: rootViewController.customNavigationBar(), toolbarClass: rootViewController.customToolbarClass())
        pushViewController(rootViewController, animated: false)
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        interactivePopGestureRecognizer?.isEnabled = false
        
        if rt.navigationController?.transferNavigationBarAttributes == true {
            navigationBar.isTranslucent   = (navigationController?.navigationBar.isTranslucent)!
            navigationBar.tintColor       = navigationController?.navigationBar.tintColor
            navigationBar.barTintColor    = navigationController?.navigationBar.barTintColor
            navigationBar.barStyle        = (navigationController?.navigationBar.barStyle)!
            navigationBar.backgroundColor = navigationController?.navigationBar.backgroundColor
            
            navigationBar.setBackgroundImage(navigationController?.navigationBar.backgroundImage(for: .`default`), for: .`default`)
            navigationBar.setTitleVerticalPositionAdjustment((navigationController?.navigationBar.titleVerticalPositionAdjustment(for: .`default`))!, for: .`default`)
            
            navigationBar.titleTextAttributes              = navigationController?.navigationBar.titleTextAttributes;
            navigationBar.shadowImage                      = navigationController?.navigationBar.shadowImage;
            navigationBar.backIndicatorImage               = navigationController?.navigationBar.backIndicatorImage;
            navigationBar.backIndicatorTransitionMaskImage = navigationController?.navigationBar.backIndicatorTransitionMaskImage;
        }
        view.layoutIfNeeded()
    }
    
    override var tabBarController: UITabBarController? {
        let tabbarController = super.tabBarController
        let navigationController = rt.navigationController
        
        if tabbarController != nil {
            if navigationController?.tabBarController != nil {
                return tabbarController!
            }else{
                let isHidden = navigationController?.viewControllers.operation { (item) -> Bool in
                    return item.hidesBottomBarWhenPushed
                }
                return (!(tabbarController?.tabBar.isTranslucent)! || isHidden ?? false) ? nil : tabbarController!
            }
        }
        return nil
    }
    
    override var viewControllers: [UIViewController] {
        
        set {
            if navigationController != nil {
                navigationController?.viewControllers = newValue
            }else {
                super.viewControllers = newValue
            }
        }
        
        get {
            if navigationController != nil {
                if navigationController is RTRootNavigationController {
                    return (rt.navigationController?.rt_viewControllers)!
                }
            }
            return super.viewControllers
        }
    }
    
    override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        guard #available(iOS 9.0, *) else {
            if navigationController != nil {
                
                return self.navigationController?.forUnwindSegueAction(_:action,from:fromViewController,withSender:sender)
            }
            return super.forUnwindSegueAction(_:action,from:fromViewController,withSender:sender)
        }
        return nil
    }
    
    @available(iOS 9.0, *)
    override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        if navigationController != nil {
            return self.navigationController?.allowedChildrenForUnwinding(from:source) ?? []
        }
        return super.allowedChildrenForUnwinding(from:source)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if navigationController != nil {
            navigationController?.pushViewController(viewController, animated: animated)
        }else {
            super.pushViewController(viewController, animated: animated)
        }
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        if navigationController != nil {
            return navigationController?.popViewController(animated: animated)
        }
        return super.popViewController(animated: animated)
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        if navigationController != nil {
            return navigationController?.popToRootViewController(animated: animated)
        }
        return super.popToRootViewController(animated: animated)
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        if navigationController != nil {
            return navigationController?.popToViewController(viewController,animated: animated)
        }
        return super.popToViewController(viewController,animated: animated)
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let _ = navigationController?.responds(to: aSelector) {
            return navigationController
        }
        return nil
    }
    
    override var delegate: UINavigationControllerDelegate? {
        set {
            if navigationController != nil {
                navigationController?.delegate = newValue
            }else {
                super.delegate = newValue
            }
        }
        
        get {
            return navigationController != nil ? navigationController?.delegate : super.delegate
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return (topViewController?.preferredStatusBarStyle)!
    }
    
    override var prefersStatusBarHidden: Bool {
        return (topViewController?.prefersStatusBarHidden)!
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return (topViewController?.preferredStatusBarUpdateAnimation)!
    }
    
}
