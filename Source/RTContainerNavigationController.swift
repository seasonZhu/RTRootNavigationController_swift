//
//  RTContainerNavigationController.swift
//  
//
//  Created by season on 2019/11/11.
//

import UIKit

/// RTContainerNavigationController
open class RTContainerNavigationController: UINavigationController {
    
    override init(rootViewController: UIViewController) {
        super.init(navigationBarClass: rootViewController.customNavigationBar(), toolbarClass: nil)
        self.pushViewController(rootViewController, animated: false)
    }
    
    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.interactivePopGestureRecognizer?.isEnabled = false
        
        if self.rt.navigationController?.transferNavigationBarAttributes == true {
            self.navigationBar.isTranslucent   = (self.navigationController?.navigationBar.isTranslucent)!;
            self.navigationBar.tintColor       = self.navigationController?.navigationBar.tintColor;
            self.navigationBar.barTintColor    = self.navigationController?.navigationBar.barTintColor;
            self.navigationBar.barStyle        = (self.navigationController?.navigationBar.barStyle)!;
            self.navigationBar.backgroundColor = self.navigationController?.navigationBar.backgroundColor;
            
            self.navigationBar.setBackgroundImage(self.navigationController?.navigationBar.backgroundImage(for: .`default`), for: .`default`)
            self.navigationBar.setTitleVerticalPositionAdjustment((self.navigationController?.navigationBar.titleVerticalPositionAdjustment(for: .`default`))!, for: .`default`)
            
            self.navigationBar.titleTextAttributes              = self.navigationController?.navigationBar.titleTextAttributes;
            self.navigationBar.shadowImage                      = self.navigationController?.navigationBar.shadowImage;
            self.navigationBar.backIndicatorImage               = self.navigationController?.navigationBar.backIndicatorImage;
            self.navigationBar.backIndicatorTransitionMaskImage = self.navigationController?.navigationBar.backIndicatorTransitionMaskImage;
        }
        self.view.layoutIfNeeded()
    }
    
    open override var tabBarController: UITabBarController? {
        let tabbarController = super.tabBarController
        let navigationController = self.rt.navigationController
        
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
    
    open override var viewControllers: [UIViewController] {
        
        set {
            if self.navigationController != nil {
                self.navigationController?.viewControllers = newValue
            }else{
                super.viewControllers = newValue
            }
        }
        
        get {
            if self.navigationController != nil {
                if self.navigationController is RTRootNavigationController {
                    return (self.rt.navigationController?.rt_viewControllers)!
                }
            }
            return super.viewControllers
        }
    }
    
    open override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        guard #available(iOS 9.0, *) else{
            if(self.navigationController != nil) {
                return self.navigationController?.forUnwindSegueAction(_:action,from:fromViewController,withSender:sender)
            }
            return super.forUnwindSegueAction(_:action,from:fromViewController,withSender:sender)
        }
        return nil
    }
    
    @available(iOS 9.0, *)
    open override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        if(self.navigationController != nil) {
            return self.navigationController?.allowedChildrenForUnwinding(from:source) ?? []
        }
        return super.allowedChildrenForUnwinding(from:source)
    }
    
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if(self.navigationController != nil) {
            self.navigationController?.pushViewController(viewController, animated: animated)
        }else{
            super.pushViewController(viewController, animated: animated)
        }
    }
    
    open override func popViewController(animated: Bool) -> UIViewController? {
        if(self.navigationController != nil) {
            return self.navigationController?.popViewController(animated: animated)
        }
        return super.popViewController(animated: animated)
    }
    
    open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        if(self.navigationController != nil) {
            return self.navigationController?.popToRootViewController(animated: animated)
        }
        return super.popToRootViewController(animated: animated)
    }
    
    open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        if(self.navigationController != nil) {
            return self.navigationController?.popToViewController(viewController,animated: animated)
        }
        return super.popToViewController(viewController,animated: animated)
    }
    
    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if let _ = self.navigationController?.responds(to: aSelector) {
            return self.navigationController
        }
        return nil
    }
    
    open override var delegate: UINavigationControllerDelegate? {
        set {
            if(self.navigationController != nil){
                self.navigationController?.delegate = newValue
            }else{
                super.delegate = newValue
            }
        }
        
        get {
            return (self.navigationController != nil) ? self.navigationController?.delegate : super.delegate
        }
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return (self.topViewController?.preferredStatusBarStyle)!
    }
    
    open override var prefersStatusBarHidden: Bool {
        return (self.topViewController?.prefersStatusBarHidden)!
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return (self.topViewController?.preferredStatusBarUpdateAnimation)!
    }
    
}
