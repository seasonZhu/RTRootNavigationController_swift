//
//  RTNavigationComponentCustomizable.swift
//
//
//  Created by season on 2019/11/8.
//

import UIKit

@objc protocol RTNavigationComponentCustomizable {
    
    func customBackItemWithTarget(target: Any, action: Selector) -> UIBarButtonItem?
    
    func customNavigationBar() -> AnyClass?
    
}
