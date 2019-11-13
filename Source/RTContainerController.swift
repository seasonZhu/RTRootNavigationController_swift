//
//  RTContainerController.swift
//  
//
//  Created by season on 2019/11/11.
//

import UIKit

public class RTContainerController: UIViewController {
    
    public private(set) var contentViewController: UIViewController?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var containerNavigationController: UINavigationController?
    
    init(controller: UIViewController, navigationBarClass: AnyClass?, toolbarClass: AnyClass?, withPlaceholder: Bool, backItem: UIBarButtonItem?, backTitle: String?) {
        
        super.init(nibName:nil,bundle:nil)
        
        contentViewController = controller
        containerNavigationController = RTContainerNavigationController(navigationBarClass:navigationBarClass, toolbarClass: toolbarClass)
        
        if withPlaceholder {
            let vc = UIViewController()
            vc.title = backTitle
            vc.navigationItem.backBarButtonItem = backItem
            containerNavigationController?.viewControllers = [vc,controller]
        }else{
            containerNavigationController?.viewControllers = [controller]
        }
        
        addChild(self.containerNavigationController!)
        containerNavigationController?.didMove(toParent: self)
    }
    
    init(contentController: UIViewController) {
        super.init(nibName:nil,bundle:nil)
        contentViewController = contentController
        addChild(self.contentViewController!)
        contentViewController?.didMove(toParent: self)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if let containerNav = self.containerNavigationController {
            containerNav.view.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            view.addSubview(containerNav.view)
            containerNav.view.frame = view.bounds
        }else {
            contentViewController?.view.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            contentViewController?.view.frame = view.bounds
            view.addSubview((contentViewController?.view)!)
        }
    }
    
    public override var shouldAutorotate: Bool {
        return (contentViewController?.shouldAutorotate)!
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (contentViewController?.supportedInterfaceOrientations)!
    }
    
    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return (contentViewController?.preferredInterfaceOrientationForPresentation)!
    }
    
    public override func becomeFirstResponder() -> Bool {
        return (contentViewController?.becomeFirstResponder())!
    }
    
    public override var canBecomeFirstResponder: Bool {
        return (contentViewController?.canBecomeFirstResponder)!
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return (contentViewController?.preferredStatusBarStyle)!
    }
    
    public override var prefersStatusBarHidden: Bool {
        return (contentViewController?.prefersStatusBarHidden)!
    }
    
    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return (contentViewController?.preferredStatusBarUpdateAnimation)!
    }
    
    @available(iOS 11.0, *)
    public override var prefersHomeIndicatorAutoHidden: Bool {
        return (contentViewController?.prefersHomeIndicatorAutoHidden)!
    }
    
    @available(iOS 11.0, *)
    public override var childForHomeIndicatorAutoHidden: UIViewController? {
        return contentViewController
    }

    public override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        guard #available(iOS 9.0, *) else{
            let viewController = contentViewController?.forUnwindSegueAction(_:action,from:fromViewController,withSender:sender)
            return viewController
        }
        return nil
    }
    
    @available(iOS 9.0, *)
    public override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        return contentViewController?.allowedChildrenForUnwinding(from:source) ?? []
    }
    
    public override var hidesBottomBarWhenPushed: Bool {
        set {
            super.hidesBottomBarWhenPushed = newValue
        }
        get {
            return (contentViewController?.hidesBottomBarWhenPushed)!
        }
    }
    
    public override var title: String? {
        set{
            super.title = newValue
        }
        get{
            return contentViewController?.title
        }
    }
    
    public override var tabBarItem: UITabBarItem! {
        set{
            super.tabBarItem = newValue
        }
        get{
            return contentViewController?.tabBarItem
        }
    }
}

internal func RTSafeWrapViewController(controller: UIViewController,
                                       navigationBarClass: AnyClass?,
                                       toolbarClass: AnyClass?,
                                       withPlaceholder: Bool = false,
                                       backItem: UIBarButtonItem? = nil,
                                       backTitle: String? = nil) -> UIViewController {
    return RTContainerController(controller: controller,
                                 navigationBarClass: navigationBarClass,
                                 toolbarClass: toolbarClass,
                                 withPlaceholder: withPlaceholder,
                                 backItem: backItem,
                                 backTitle: backTitle)
}

internal func RTSafeUnwrapViewController(wrapVC controller: UIViewController?) -> UIViewController? {
    if let contentVC = (controller as? RTContainerController)?.contentViewController {
        return contentVC
    }
    return controller
}
