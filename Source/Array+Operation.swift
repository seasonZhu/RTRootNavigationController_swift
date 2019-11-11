//
//  Array+Operation.swift
//  
//
//  Created by season on 2019/11/8.
//

import Foundation

/// 数组扩展
public extension Array {
    
    func operation(_ operation: (Element) -> Bool) -> Bool {
        var result = false
        for item in self {
            if operation(item){
                result = true
                break
            }
        }
        return result
    }
    
}
