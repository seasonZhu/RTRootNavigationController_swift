# 使用 Swift 定制协议与每页导航容器

以 master@9d2927c 和 develop_custom_onBack@4f777cd 的功能为基线，保留每页 UINavigationController 的容器结构，使业务页面仍可通过 navigationController 操作导航。Swift 无法直接照搬 Objective-C 分类方法覆盖，改由 RTNavigationCustomizing 协议提供定制点；允许关联对象保存页面设置，不要求业务页面继承专用基类。此次不保证旧 Swift 或 Objective-C 源码兼容，最低 iOS 13。
