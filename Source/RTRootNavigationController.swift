//
//  RTRootNavigationController.swift
//
//
//  Created by season on 2019/11/8.
//

import UIKit


open class RTRootNavigationController: UINavigationController {
    
    // MARK: fileprivate
    fileprivate var animationComplete: ((Bool) -> Swift.Void)?
    
    fileprivate var rt_Delegate: UINavigationControllerDelegate?
    
    
    // MARK: override
    
    open override var delegate: UINavigationControllerDelegate? {
        set {
            self.rt.delegate = newValue
        }
        get {
            return self.rt.delegate
        }
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.viewControllers = super.viewControllers
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        self.commonInit()
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.commonInit()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(rootViewControllerNoWrapping: UIViewController) {
        super.init(rootViewController: RTContainerController(contentController: rootViewControllerNoWrapping))
        self.commonInit()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        super.delegate = self
        super.setNavigationBarHidden(true, animated: false)
    }
    
    open override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        guard #available(iOS 9.0, *) else{
            var controller: UIViewController? = super.forUnwindSegueAction(action, from: fromViewController, withSender: sender)
            
            if controller == nil {
                let index = self.viewControllers.index(of: fromViewController)
                if index != NSNotFound {
                    for i in (index! - 1)...0  {
                        controller = self.viewControllers[i].forUnwindSegueAction(action, from: fromViewController, withSender: sender)
                        
                        if controller != nil {break}
                    }
                }
                
            }
            return controller
        }
        return nil
    }
    
    @available(iOS 9.0, *)
    open override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        var controller: [UIViewController]? = super.allowedChildrenForUnwinding(from: source)
        
        if controller?.count == 0 {
            let index = self.viewControllers.index(of: source.source)
            if index != NSNotFound {
                for i in (index! - 1)...0  {
                    controller = self.viewControllers[i].allowedChildrenForUnwinding(from: source)
                    
                    if controller?.count != 0 {break}
                }
            }
            
        }
        return controller ?? []
    }
    
    open override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {

    }
    
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.viewControllers.count > 0 {
            let currentLast = RTSafeUnwrapViewController(wrapVC: self.viewControllers.last!)!

            super.pushViewController(RTSafeWrapViewController(controller: viewController, navigationBarClass: viewController.customNavigationBar(), withPlaceholder: self.useSystemBackBarButtonItem, backItem: currentLast.navigationItem.backBarButtonItem, backTitle: currentLast.navigationItem.title), animated: animated)
        }else {
            super.pushViewController(RTSafeWrapViewController(controller: viewController, navigationBarClass: viewController.customNavigationBar()), animated: animated)
        }
    }
    
    open override func popViewController(animated: Bool) -> UIViewController? {
        return RTSafeUnwrapViewController(wrapVC: super.popViewController(animated: animated)!)
    }
    
    open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        return super.popToRootViewController(animated: animated)?.map{
            return RTSafeUnwrapViewController(wrapVC: $0)!
        }
    }
    
    open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        
        var controllerToPop :UIViewController?
        
        for vc in super.viewControllers {
            if(RTSafeUnwrapViewController(wrapVC: vc) == viewController) {
                controllerToPop = vc
                break
            }
        }
        
        if let ctp = controllerToPop {
            return super.popToViewController(ctp, animated: animated)?.map {
                return RTSafeUnwrapViewController(wrapVC: $0)!
            }
        }
        return nil
    }
    
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        
        super.setViewControllers(viewControllers.enumerated().map{ (index,item) in
            if self.useSystemBackBarButtonItem && index > 0 {
                return RTSafeWrapViewController(controller: item, navigationBarClass: item.customNavigationBar(), withPlaceholder: self.useSystemBackBarButtonItem, backItem: viewControllers[index - 1].navigationItem.backBarButtonItem, backTitle: viewControllers[index - 1].navigationItem.title)
            }else{
                return RTSafeWrapViewController(controller: item, navigationBarClass: item.customNavigationBar())
            }
            
        }, animated: animated)
    }
    
    open override var shouldAutorotate: Bool {
        return (self.topViewController?.shouldAutorotate)!
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (self.topViewController?.supportedInterfaceOrientations)!
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return (self.topViewController?.preferredInterfaceOrientationForPresentation)!
    }
    
    
    open override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector){
            return true
        }
        return self.rt.delegate?.responds(to:aSelector) ?? false
    }
    
    open override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return self.rt.delegate
    }

    
    // MARK: Public
    public var transferNavigationBarAttributes: Bool = false
    
    public var useSystemBackBarButtonItem: Bool = false
    
    public func removeViewController(controller: UIViewController, animated flag: Bool = false) {
        
        var viewControllers = super.viewControllers
        var controllerToRemove: UIViewController?
        
        for vc in viewControllers where RTSafeUnwrapViewController(wrapVC: vc) == controller {
            controllerToRemove = vc
            break
        }
        
        if let ctp = controllerToRemove, let index = viewControllers.index(of: ctp){
            viewControllers.remove(at: index)
            super.setViewControllers(viewControllers, animated: flag)
        }
    }
    
    public func pushViewController(viewController: UIViewController, animated: Bool, complete: @escaping (Bool) -> Swift.Void){
        self.animationComplete?(false)
        self.animationComplete = complete
        self.pushViewController(viewController, animated: animated)
        
        self.animationComplete?(true)
        self.animationComplete = nil
    }
    
    public func popViewController(animated: Bool, complete: @escaping (Bool) -> Swift.Void) -> UIViewController? {
        self.animationComplete?(false)
        self.animationComplete = complete
        
        let vc = self.popViewController(animated: animated)
        
        self.animationComplete?(true)
        self.animationComplete = nil
        
        return vc
    }
    
    public func popToViewController(viewController: UIViewController, animated: Bool, complete: @escaping (Bool) -> Swift.Void) -> [UIViewController]? {
        
        self.animationComplete?(false)
        self.animationComplete = complete
        
        let vcs = self.popToViewController(viewController, animated: animated)
        
        if let count = vcs?.count,count > 0 {
            self.animationComplete?(true)
            self.animationComplete = nil
        }
        return vcs
    }
    
    public func popToRootViewController(animated: Bool, complete: @escaping (Bool) -> Swift.Void) -> [UIViewController]? {
        
        self.animationComplete?(false)
        self.animationComplete = complete
        
        let vcs = self.popToRootViewController(animated: animated)
        
        if let count = vcs?.count,count > 0 {
            self.animationComplete?(true)
            self.animationComplete = nil
        }
        return vcs
    }
}

// MARK:- internal function
extension RTRootNavigationController {
    
    var rt_topViewController: UIViewController? {
        return RTSafeUnwrapViewController(wrapVC: super.topViewController)
        
    }
    
    var rt_visibleViewController: UIViewController? {
        return RTSafeUnwrapViewController(wrapVC: super.visibleViewController)
    }
    
    var rt_viewControllers: [UIViewController]? {
        return super.viewControllers.map{
            return RTSafeUnwrapViewController(wrapVC: $0)!
        }
    }
    
    @objc func onBack(sender: Any) {
        _ = self.popViewController(animated: true)
    }
    
    func commonInit() {
        
    }
}

// MARK: - UINavigationControllerDelegate
extension RTRootNavigationController: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        let isRootVC = viewController == navigationController.viewControllers.first
        let unwrapVC = RTSafeUnwrapViewController(wrapVC: viewController)!
        
        if !isRootVC {
            let hasSetLeftItem = unwrapVC.navigationItem.leftBarButtonItem != nil
            
            if hasSetLeftItem && !unwrapVC.rt.hasSetInteractivePop {
                unwrapVC.rt.disableInteractivePop = true
            }else if !unwrapVC.rt.hasSetInteractivePop {
                unwrapVC.rt.disableInteractivePop = false
            }
            
            if !self.useSystemBackBarButtonItem && !hasSetLeftItem {
                if let customBackItem = unwrapVC.customBackItemWithTarget(target: self, action: #selector(onBack(sender:))) {
                    unwrapVC.navigationItem.leftBarButtonItem = customBackItem
                }else {
                    unwrapVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title:NSLocalizedString("Back", comment: ""),style:.plain,target:self,
                    action:#selector(onBack(sender:)))
                }
            }
        }
        self.rt.delegate?.navigationController?(navigationController, willShow: viewController, animated: animated)
    }
    
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        let isRootVC = viewController == navigationController.viewControllers.first
        let unwrapVC = RTSafeUnwrapViewController(wrapVC: viewController)!
        
        if unwrapVC.rt.disableInteractivePop {
            self.interactivePopGestureRecognizer?.delegate = nil
            self.interactivePopGestureRecognizer?.isEnabled = false
        }else {
            self.interactivePopGestureRecognizer?.delaysTouchesBegan = true
            self.interactivePopGestureRecognizer?.delegate = self
            self.interactivePopGestureRecognizer?.isEnabled = !isRootVC
        }
        
        RTRootNavigationController.attemptRotationToDeviceOrientation()
        
        self.animationComplete?(true)
        self.animationComplete = nil
        
        self.rt.delegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
    }
    
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return self.rt.delegate?.navigationControllerSupportedInterfaceOrientations?(_:navigationController) ?? .all
    }
    
    public func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        return self.rt.delegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(_:navigationController) ?? .portrait
    }
    
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.rt.delegate?.navigationController?(navigationController,interactionControllerFor:animationController)
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.rt.delegate?.navigationController?(navigationController,animationControllerFor:operation,from:fromVC,to:toVC)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension RTRootNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == self.interactivePopGestureRecognizer
    }
}

extension RTCategory where Base: UIViewController {
    fileprivate var hasSetInteractivePop: Bool {
        return disableInteractivePop
    }
}

extension RTCategory where Base: RTRootNavigationController {
    fileprivate var delegate: UINavigationControllerDelegate? {
        set{
            base.rt_Delegate = newValue
        }
        
        get{
            return base.rt_Delegate
        }
    }
    
    public var topViewController: UIViewController? {
        return base.rt_topViewController
    }
    
    public var visibleViewController: UIViewController? {
        return base.rt_visibleViewController
    }
    
    public var viewControllers: [UIViewController]? {
        return base.rt_viewControllers
    }
}


