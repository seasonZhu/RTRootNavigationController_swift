import Foundation

/// 导航关联对象的唯一键；跨文件共享同一个地址。
@MainActor enum RTAssociationKeys {
    static var disablePop: UInt8 = 0
}
