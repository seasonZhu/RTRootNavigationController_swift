import Foundation

/// 手势结束时按进度和速度决定完成或取消。
enum RTInteractionDecision {
    static func shouldFinish(progress: CGFloat, velocity: CGFloat) -> Bool {
        velocity > 500 || (progress > 0.5 && velocity >= -500)
    }
}
