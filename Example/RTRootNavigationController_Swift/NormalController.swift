//
//  NormalController.swift
//  RTRootNavigationController_swift_Demo
//
//  Created by season on 2019/11/8.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit

class NormalController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "Normal"
        rt_disableInteractivePop = false
        let button = UIButton(type: .custom)
        button.setTitle("Push DisableInteractivePopController", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        button.center = view.center
        view.addSubview(button)
    }
        
    @objc
    func buttonAction(_ button: UIButton) {
        navigationController?.pushViewController(DisableInteractivePopController(), animated: true)
    }
    
    private func removeSomeVC() {
        guard var viewControllers = navigationController?.viewControllers else {
            return
        }
        
        for vc in (navigationController?.viewControllers)! where vc is PushAndRemoveController {
            if let index = viewControllers.firstIndex(of: vc) {
                viewControllers.remove(at: index)
            }
        }
        
        navigationController?.setViewControllers(viewControllers, animated: false)
    }
}
