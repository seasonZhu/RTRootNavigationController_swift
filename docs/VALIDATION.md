# 验证记录

日期：2026-10-26。工具链：Xcode 26.3（17C529）、Swift 6.2.4 编译器，Swift 5 语言模式；最低 iOS 13。

## 已执行通过

| 检查 | 结果 |
| --- | --- |
| 框架 iOS Simulator SDK 类型检查 | 无错误、无警告 |
| SPM 演示与测试目标 build-for-testing | TEST BUILD SUCCEEDED |
| CocoaPods 演示与测试目标 build-for-testing | TEST BUILD SUCCEEDED |
| CocoaPods 本地路径 pod install | 成功，无第三方框架依赖 |
| pod ipc spec | 成功 |
| pod lib lint --allow-warnings --skip-tests | passed validation；包含框架构建及导入验证 |
| 交互完成/取消边界判定 | 9 项实际执行通过 |
| 两种演示的已编译 Storyboard 检查 | 入口、详情场景、页面类和 unwind 连接均存在 |
| Ruby 工程脚本与 Bash 验证脚本语法 | 通过 |
| Git 差异及新增文本空白检查 | 通过 |

UIKit 回归测试共 20 个，已经在两种集成方式下编译。覆盖导航栈、代理、返回接管、外观继承、系统返回标题、自定义动画与交互控制器，以及动画完成和取消后的视图恢复。

## 验证边界

**20 个 UIKit 测试尚未执行，不能将测试编译成功视为测试运行通过。** 按本轮约定不启动模拟器，因此未实际运行 Demo，未验证手势手感、Storyboard/unwind 运行过程、视觉效果和真机系统行为。交互式 Push、转场取消、两种 TabBar 结构、旋转、状态栏、Home indicator、底栏隐藏和不同系统版本仍需后续运行验收。

pod lint 使用 `--allow-warnings` 通过；剩余警告是 GitHub 主页 URL 无法校验，以及 Xcode 的 AppIntents 元数据提取提示。最终框架类型检查没有源码警告。本轮没有验证远程包下载、发布标签或 CocoaPods 公共索引分发。

CodeGraph 已重新索引并用于导航调用关系复核。由于旧文件仍以待删除状态保留在 Git 索引中，完整索引曾报告旧路径不存在；新源码的符号查询正常可用。

## 复现

```bash
bash scripts/verify.sh
pod lib lint RTRootNavigationController_Swift.podspec --allow-warnings --skip-tests
```

验证脚本不会执行 UIKit 测试或启动模拟器。需要运行 UIKit 用例时，可在 Xcode 中选择 `DemoSPM` 或 `DemoCocoaPods` 的测试目标和实际设备后执行测试。

本轮日志：

- `/private/tmp/RTSwift-SPM-build.log`
- `/private/tmp/RTSwift-Pods-build.log`
- `/private/tmp/RTSwift-pod-install.log`
- `/private/tmp/RTSwift-pod-lint.log`
- `/private/tmp/RTSwift-typecheck.log`

## 仓库保护

分支：`codex/swift-rebuild`，原 `.git`、远端和提交历史保留；本次重建与提交前修复统一本地提交；未推送或发布。

旧工作区归档：`/private/tmp/RTRootNavigationController_Swift-backup-20261026-141851.tar.gz`，包含删除前的未提交工程与 Pods 内容。临时目录不保证长期保留；需要长期保存时，将归档复制至持久目录。

## 提交前审查

检查框架导航栈、完成回调、容器转发、交互式 Push、演示入口、两种集成工程及资源生成脚本，保留既定架构，不做候选重构。

修复两条回调重入路径：旧完成回调同步发起新操作时，外层被替换的操作不再继续导航或覆盖目标；同步 didShow 完成回调开启新操作时，旧操作后续收尾不会提前完成新回调。补充替换回调重入、同步 didShow 重入和取消后单次完成的 3 个用例。

修复后的 20 个 UIKit 用例在 SPM 与 CocoaPods 下均再次编译通过，pod lib lint 再次通过；9 项独立判定测试与两套 Storyboard 产物检查再次通过。UIKit 用例仍未运行，运行验收限制保持不变。

## rt 命名空间迁移验证（2026-10-26）

- 框架 iOS Simulator SDK 类型检查通过。
- SPM 与 CocoaPods 演示及测试目标均完成 build-for-testing；未启动模拟器、未执行 UIKit 测试。
- UIKit 用例按当前源码统计为 21 个，新增命名空间具体类型保留、包装器与页面共享交互返回偏好的检查。
- 交互完成/取消边界判定 9 项实际执行通过；两种集成方式的 Storyboard 编译资源检查通过。
- 源码、示例及测试没有遗留 `rt_` 成员引用，旧 API 不提供兼容转发。

日志入口：`/private/tmp/RTNamespace-verify-full.log`；构建、pod install 及工程资源检查产物：`/private/tmp/RTSwift-verify.zBuMKX/`。首次沙箱构建因 SwiftPM 系统缓存写入权限失败，获准访问后重新构建。
