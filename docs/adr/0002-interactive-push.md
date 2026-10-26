# 将交互式 Push 内建为 Swift 能力

原 Demo 依赖 Objective-C RTInteractivePush。为使框架、自有演示及两种集成方式共用纯 Swift 实现，使用公开的边缘手势、动画协议和 UIPercentDrivenInteractiveTransition 内建交互 Push，增加维护转场完成及取消逻辑的责任，不继续依赖原库。
