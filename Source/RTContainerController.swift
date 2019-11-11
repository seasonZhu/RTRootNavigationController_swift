//
//  RTContainerController.swift
//  
//
//  Created by season on 2019/11/11.
//

import UIKit

open class RTContainerController: UIViewController {
    
    open private(set) var contentViewController: UIViewController?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate var containerNavigationController: UINavigationController?
    
    init(controller: UIViewController, navigationBarClass: AnyClass?, withPlaceholder: Bool, backItem: UIBarButtonItem?, backTitle: String?) {
        
        super.init(nibName:nil,bundle:nil)
        
        self.contentViewController = controller
        self.containerNavigationController = RTContainerNavigationController(navigationBarClass:navigationBarClass,toolbarClass:nil)
        
        if withPlaceholder {
            let vc = UIViewController()
            vc.title = backTitle
            vc.navigationItem.backBarButtonItem = backItem
            self.containerNavigationController?.viewControllers = [vc,controller]
        }else{
            self.containerNavigationController?.viewControllers = [controller]
        }
        
        self.addChild(self.containerNavigationController!)
        self.containerNavigationController?.didMove(toParent: self)
    }
    
    init(contentController: UIViewController) {
        super.init(nibName:nil,bundle:nil)
        self.contentViewController = contentController
        self.addChild(self.contentViewController!)
        self.contentViewController?.didMove(toParent: self)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if let containerNav = self.containerNavigationController{
            containerNav.view.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            self.view.addSubview(containerNav.view)
            containerNav.view.frame = self.view.bounds
        }else{
            self.contentViewController?.view.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            self.contentViewController?.view.frame = self.view.bounds
            self.view.addSubview((self.contentViewController?.view)!)
        }
    }
    
    open override var shouldAutorotate: Bool {
        return (self.contentViewController?.shouldAutorotate)!
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (self.contentViewController?.supportedInterfaceOrientations)!
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return (self.contentViewController?.preferredInterfaceOrientationForPresentation)!
    }
    
    open override func becomeFirstResponder() -> Bool {
        return (self.contentViewController?.becomeFirstResponder())!
    }
    
    open override var canBecomeFirstResponder: Bool {
        return (self.contentViewController?.canBecomeFirstResponder)!
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        return (self.contentViewController?.preferredStatusBarStyle)!
    }
    
    open override var prefersStatusBarHidden: Bool {
        return (self.contentViewController?.prefersStatusBarHidden)!
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return (self.contentViewController?.preferredStatusBarUpdateAnimation)!
    }
    
    @available(iOS 11.0, *)
    open override var prefersHomeIndicatorAutoHidden: Bool {
        return (self.contentViewController?.prefersHomeIndicatorAutoHidden)!
    }
    
    @available(iOS 11.0, *)
    open override var childForHomeIndicatorAutoHidden: UIViewController? {
        return self.contentViewController
    }

    open override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        guard #available(iOS 9.0, *) else{
            let viewController = self.contentViewController?.forUnwindSegueAction(_:action,from:fromViewController,withSender:sender)
            return viewController
        }
        return nil
    }
    
    @available(iOS 9.0, *)
    open override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        return self.contentViewController?.allowedChildrenForUnwinding(from:source) ?? []
    }
    
    open override var hidesBottomBarWhenPushed: Bool {
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
        get {
            return (contentViewController?.hidesBottomBarWhenPushed)!
        }
    }
    
    open override var title: String? {
        set{
            super.title = newValue
        }
        get{
            return contentViewController?.title
        }
    }
    
    open override var tabBarItem: UITabBarItem! {
        set{
            super.tabBarItem = newValue
        }
        get{
            return contentViewController?.tabBarItem
        }
    }
}

internal func RTSafeWrapViewController(controller: UIViewController, navigationBarClass: AnyClass?, withPlaceholder: Bool = false, backItem: UIBarButtonItem? = nil, backTitle: String? = nil) -> UIViewController {
    return RTContainerController(controller:controller,navigationBarClass:navigationBarClass,withPlaceholder:withPlaceholder,backItem:backItem,backTitle:backTitle)
}

internal func RTSafeUnwrapViewController(wrapVC controller: UIViewController?) -> UIViewController? {
    if let contentVC = (controller as? RTContainerController)?.contentViewController {
        return contentVC
    }
    return controller
}
