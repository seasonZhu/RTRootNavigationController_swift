import Foundation

/// 独立执行的跨平台判定测试，不启动应用或模拟器。
@main struct InteractionChecks {
    static func main() {
        let cases: [(CGFloat, CGFloat, Bool)] = [
            (0, 0, false), (0.2, 0, false), (0.5, 0, false), (0.51, 0, true),
            (1, 0, true), (0.1, 501, true), (0.1, 500, false),
            (0.9, -501, false), (0.9, -500, true)
        ]
        for (progress, velocity, expected) in cases {
            precondition(RTInteractionDecision.shouldFinish(progress: progress, velocity: velocity) == expected)
        }
        print("交互完成/取消判定：\(cases.count) 项通过")
    }
}
