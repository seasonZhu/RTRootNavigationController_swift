# 执行记录

备份：/private/tmp/RTRootNavigationController_Swift-backup-20261026-141851.tar.gz，已验证归档内容。
分支：codex/swift-rebuild。首次创建因沙箱无法写 .git 失败，提权后成功。
CodeGraph 已初始化；旧索引随重建失效，后续重新索引。

框架、两套演示工程、中文文档已建立。初次 Xcode 构建受缓存沙箱限制；提权后两种 build-for-testing 均通过。类型检查发现 unwind 参数标签不符，修正后发现该 API 已废弃，最终移除多余旧接口覆盖，保留现代 UIKit 容器遍历。已补充系统返回标题刷新及完成回调代次隔离。

Storyboard 产物检查发现初稿缺少 sceneMemberID，虽编译成功但场景为空；已修复场景标记及两种模块通用的页面类名称。重新构建均通过，并检查入口、页面类、show/unwind 资源。新增独立产物检查脚本。

最终结果：SPM 与 CocoaPods 的 Demo 和 17 个 UIKit 测试均编译通过。9 项独立判定测试实际执行通过，两种 Storyboard 产物检查通过，最终框架类型检查无警告。pod lib lint 通过（URL 校验警告与 Xcode 元数据提示），未执行 UIKit 测试或模拟器交互。详情见 docs/VALIDATION.md。

提交前审查：修复完成回调的两种同步重入路径，新增 3 个用例。当前 20 个 UIKit 用例在两套集成工程下编译通过；9 项独立判定、Storyboard 产物检查与 pod lib lint 再次通过。中文工程分组已改为 Shared/Resources/Tests。全部重建与修复改动统一纳入本地提交，不推送。
