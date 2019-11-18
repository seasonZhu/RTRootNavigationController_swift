//
//  RTRootNavigationController.swift
//
//
//  Created by season on 2019/11/8.
//

import UIKit


public class RTRootNavigationController: UINavigationController {
    
    // MARK:- fileprivate
    fileprivate var animationComplete: ((Bool) -> Swift.Void)?
    
    fileprivate var rt_Delegate: UINavigationControllerDelegate?
    
    // MARK:- override
    public override var delegate: UINavigationControllerDelegate? {
        set {
            self.rt.delegate = newValue
        }
        get {
            return self.rt.delegate
        }
    }
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.viewControllers = super.viewControllers
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        commonInit()
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        commonInit()
    }
    
    public init(rootViewControllerNoWrapping: UIViewController) {
        super.init(rootViewController: RTContainerController(contentController: rootViewControllerNoWrapping))
        commonInit()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        super.delegate = self
        super.setNavigationBarHidden(true, animated: false)
    }
    
    public override func forUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any?) -> UIViewController? {
        guard #available(iOS 9.0, *) else{
            var controller: UIViewController? = super.forUnwindSegueAction(action, from: fromViewController, withSender: sender)
            
            if controller == nil {
                if let index = viewControllers.firstIndex(of: fromViewController) {
                    for i in (index - 1)...0  {
                        controller = viewControllers[i].forUnwindSegueAction(action, from: fromViewController, withSender: sender)
                        
                        if controller != nil { break }
                    }
                }
                
            }
            return controller
        }
        return nil
    }
    
    @available(iOS 9.0, *)
    public override func allowedChildrenForUnwinding(from source: UIStoryboardUnwindSegueSource) -> [UIViewController] {
        var controller: [UIViewController]? = super.allowedChildrenForUnwinding(from: source)
        
        if controller?.count == 0 {
            if let index = viewControllers.firstIndex(of: source.source) {
                for i in (index - 1)...0  {
                    controller = self.viewControllers[i].allowedChildrenForUnwinding(from: source)
                    
                    if controller?.count != 0 { break }
                }
            }
            
        }
        return controller ?? []
    }
    
    public override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(hidden, animated: animated)
        
    }
    
    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.viewControllers.count > 0 {
            let currentLast = RTSafeUnwrapViewController(wrapVC: viewControllers.last!)!
            let safeWrapVC = RTSafeWrapViewController(controller: viewController,
                                             navigationBarClass: viewController.customNavigationBar(),
                                             toolbarClass: viewController.customToolbarClass(),
                                             withPlaceholder: useSystemBackBarButtonItem,
                                             backItem: currentLast.navigationItem.backBarButtonItem,
                                             backTitle: currentLast.navigationItem.title)
            super.pushViewController(safeWrapVC, animated: animated)
        }else {
            let safeWrapVC = RTSafeWrapViewController(controller: viewController,
                                                      navigationBarClass: viewController.customNavigationBar(),
                                                      toolbarClass: viewController.customToolbarClass())
            super.pushViewController(safeWrapVC, animated: animated)
        }
    }
    
    public override func popViewController(animated: Bool) -> UIViewController? {
        return RTSafeUnwrapViewController(wrapVC: super.popViewController(animated: animated))
    }
    
    public override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        return super.popToRootViewController(animated: animated)?.compactMap {
            return RTSafeUnwrapViewController(wrapVC: $0)!
        }
    }
    
    public override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        
        var controllerToPop :UIViewController?
        
        for vc in super.viewControllers where RTSafeUnwrapViewController(wrapVC: vc) == viewController {
            controllerToPop = vc
            break
        }
        
        if let ctp = controllerToPop {
            return super.popToViewController(ctp, animated: animated)?.map {
                return RTSafeUnwrapViewController(wrapVC: $0)!
            }
        }
        return nil
    }
    /*
    public override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        
        super.setViewControllers(viewControllers.enumerated().map { (index, item) in
            if useSystemBackBarButtonItem && index > 0 {
                return RTSafeWrapViewController(controller: item,
                                                navigationBarClass: item.customNavigationBar(),
                                                toolbarClass: item.customToolbarClass(),
                                                withPlaceholder: useSystemBackBarButtonItem,
                                                backItem: viewControllers[index - 1].navigationItem.backBarButtonItem,
                                                backTitle: viewControllers[index - 1].navigationItem.title)
            }else {
                return RTSafeWrapViewController(controller: item,
                                                navigationBarClass: item.customNavigationBar(),
                                                toolbarClass: item.customToolbarClass())
            }
        }, animated: animated)
    }
    */
    public override var shouldAutorotate: Bool {
        return (topViewController?.shouldAutorotate)!
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (topViewController?.supportedInterfaceOrientations)!
    }
    
    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return (topViewController?.preferredInterfaceOrientationForPresentation)!
    }
    
    public override func responds(to aSelector: Selector!) -> Bool {
        if super.responds(to: aSelector){
            return true
        }
        return rt.delegate?.responds(to:aSelector) ?? false
    }
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return rt.delegate
    }

    
    // MARK: Public
    @IBInspectable public var transferNavigationBarAttributes: Bool = false
    
    @IBInspectable public var useSystemBackBarButtonItem: Bool = false
    
    public func removeViewController(controller: UIViewController, animated flag: Bool = false) {
        
        var viewControllers = super.viewControllers
        var controllerToRemove: UIViewController?
        
        for vc in viewControllers where RTSafeUnwrapViewController(wrapVC: vc) == controller {
            controllerToRemove = vc
            break
        }
        
        if let ctp = controllerToRemove, let index = viewControllers.firstIndex(of: ctp) {
            viewControllers.remove(at: index)
            // 这个地方的setViewControllers会调用当前类中的setViewControllers,导致出了问题,而OC版本不会
            super.setViewControllers(viewControllers, animated: flag)
        }
    }
    
    public func pushViewController(viewController: UIViewController, animated: Bool, complete: @escaping (Bool) -> Swift.Void){
        animationComplete?(false)
        animationComplete = complete
        pushViewController(viewController, animated: animated)
        
        animationComplete?(true)
        animationComplete = nil
    }
    
    public func popViewController(animated: Bool, complete: @escaping (Bool) -> Swift.Void) -> UIViewController? {
        animationComplete?(false)
        animationComplete = complete
        
        let vc = self.popViewController(animated: animated)
        
        animationComplete?(true)
        animationComplete = nil
        
        return vc
    }
    
    public func popToViewController(viewController: UIViewController, animated: Bool, complete: @escaping (Bool) -> Swift.Void) -> [UIViewController]? {
        
        animationComplete?(false)
        animationComplete = complete
        
        let vcs = self.popToViewController(viewController, animated: animated)
        
        if let count = vcs?.count, count > 0 {
            animationComplete?(true)
        }
        animationComplete = nil
        return vcs
    }
    
    public func popToRootViewController(animated: Bool, complete: @escaping (Bool) -> Swift.Void) -> [UIViewController]? {
        
        animationComplete?(false)
        animationComplete = complete
        
        let vcs = self.popToRootViewController(animated: animated)
        
        if let count = vcs?.count, count > 0 {
            animationComplete?(true)
        }
        animationComplete = nil
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
        return super.viewControllers.compactMap {
            return RTSafeUnwrapViewController(wrapVC: $0)!
        }
    }
    
    func commonInit() {
        
    }
    
    @objc
    func onBack(sender: Any) {
        _ = self.popViewController(animated: true)
    }
}

// MARK:- UINavigationControllerDelegate
extension RTRootNavigationController: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        let isRootVC = viewController == navigationController.viewControllers.first
        let unwrapVC = RTSafeUnwrapViewController(wrapVC: viewController)!
        
        if !isRootVC {
            let hasSetLeftItem = unwrapVC.navigationItem.leftBarButtonItem != nil
            
            /*
            if hasSetLeftItem && !unwrapVC.rt.hasSetInteractivePop {
                unwrapVC.rt.disableInteractivePop = true
            }else if !unwrapVC.rt.hasSetInteractivePop {
                unwrapVC.rt.disableInteractivePop = false
            }
            */
            
            if !useSystemBackBarButtonItem && !hasSetLeftItem {
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
        
        if !animated {
            let _ = unwrapVC.view
        }
        
        if unwrapVC.rt.disableInteractivePop {
            interactivePopGestureRecognizer?.delegate = nil
            interactivePopGestureRecognizer?.isEnabled = false
        }else {
            interactivePopGestureRecognizer?.delaysTouchesBegan = true
            interactivePopGestureRecognizer?.delegate = self
            interactivePopGestureRecognizer?.isEnabled = !isRootVC
        }
        
        RTRootNavigationController.attemptRotationToDeviceOrientation()
        
        animationComplete?(true)
        animationComplete = nil
        
        rt.delegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
    }
    
    public func navigationControllerSupportedInterfaceOrientations(_ navigationController: UINavigationController) -> UIInterfaceOrientationMask {
        return rt.delegate?.navigationControllerSupportedInterfaceOrientations?(_:navigationController) ?? .all
    }
    
    public func navigationControllerPreferredInterfaceOrientationForPresentation(_ navigationController: UINavigationController) -> UIInterfaceOrientation {
        return rt.delegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(_:navigationController) ?? .portrait
    }
    
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return rt.delegate?.navigationController?(navigationController,interactionControllerFor:animationController)
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return rt.delegate?.navigationController?(navigationController,animationControllerFor:operation,from:fromVC,to:toVC)
    }
}

// MARK:- UIGestureRecognizerDelegate
extension RTRootNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == interactivePopGestureRecognizer
    }
}

// MARK:- RTCategory About RTRootNavigationController
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
