import UIKit

/// 弱引用框架生成的返回按钮，避免记录表延长按钮生命周期。
final class WeakBarItem {
    weak var item: UIBarButtonItem?

    init(_ item: UIBarButtonItem) { self.item = item }
}
