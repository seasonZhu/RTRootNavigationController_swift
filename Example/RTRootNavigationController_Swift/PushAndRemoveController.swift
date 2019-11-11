//
//  PushAndRemoveController.swift
//  RTRootNavigationController_swift_Demo
//
//  Created by season on 2019/11/8.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit

class PushAndRemoveController: UIViewController {
    /// 这个有问题
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.gray
        let button = UIButton(type: .custom)
        button.setTitle("Push and this vc will remove", for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
        button.center = view.center
        view.addSubview(button)
    }
    
    @objc
    func buttonAction(_ button: UIButton) {
        rt_navigationController?.pushViewController(viewController: NormalController(), animated: true, complete: { (_) in
            self.rt_navigationController?.removeViewController(controller: self)
        })
    }
    
    deinit {
        print("销毁了")
    }

}
