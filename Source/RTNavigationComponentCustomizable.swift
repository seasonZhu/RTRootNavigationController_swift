//
//  RTNavigationComponentCustomizable.swift
//
//
//  Created by season on 2019/11/8.
//

import UIKit

/// 自定义控件协议
@objc protocol RTNavigationComponentCustomizable {
    
    func customBackItemWithTarget(target: Any, action: Selector) -> UIBarButtonItem?
    
    func customNavigationBar() -> AnyClass?
    
    func customToolbarClass() -> AnyClass?
    
}
