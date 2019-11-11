//
//  RTCompatible.swift
//
//
//  Created by season on 2019/11/8.
//

import Foundation

/// 为类添加扩展字段, 注意是类
public final class RTCategory<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

/// 类的分类拓展字段协议
public protocol RTCompatible {
    associatedtype RTCompatibleType
    var rt: RTCompatibleType { get }
}

// MARK: - 类的分类拓展字段协议的默认实现
public extension RTCompatible {
    var rt: RTCategory<Self> {
        get { return RTCategory(self) }
    }
}
