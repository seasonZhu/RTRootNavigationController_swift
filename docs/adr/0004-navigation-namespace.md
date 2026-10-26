# 使用 rt 命名空间组织导航扩展

将控制器访问与配置以及根导航器的真实栈访问迁入 `.rt`，使用保留基础控制器类型的 `RTNavigation<Base>` 包装器，仅向 UIViewController 及其子类提供入口。参考 [Kingfisher](https://github.com/onevcat/Kingfisher/blob/master/Sources/General/Kingfisher.swift) 与 [RxSwift](https://github.com/ReactiveX/RxSwift/blob/master/RxSwift/Reactive.swift) 的泛型包装器模式；可写属性通过非变异 setter 修改原页面设置，不引入响应式绑定或跨线程承诺。

RTNavigationCustomizing 和 RTViewControllerAnimatedTransitioning 的成员去掉 `rt_` 前缀，继续作为协议要求由业务类型实现，以保留协议分派。UIKit 覆盖方法及既有无前缀 API 保留原位。按此次 Swift 化的源码兼容约定，直接移除旧 `rt_` API，不提供弃用转发；示例、测试与调用方同步迁移。

真实导航栈仍指内容页面集合，UIKit 的包装栈语义保持不变。本次没有新增领域概念，沿用 GLOSSARY.md 中的术语。
