#!/bin/bash
# 仅编译测试，不启动模拟器。日志和构建产物位于临时目录。
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_BUILD_DIR="$(mktemp -d /private/tmp/RTSwift-verify.XXXXXX)"
echo "验证产物：$TASK_BUILD_DIR"
xcrun swiftc -module-cache-path "$TASK_BUILD_DIR/ModuleCache" Sources/RTRootNavigationController_Swift/RTInteractionDecision.swift scripts/test_interaction.swift -o "$TASK_BUILD_DIR/interaction-tests"
"$TASK_BUILD_DIR/interaction-tests"
pod ipc spec RTRootNavigationController_Swift.podspec > "$TASK_BUILD_DIR/podspec.json"
pod install --project-directory=Example/CocoaPods > "$TASK_BUILD_DIR/pod-install.log" 2>&1
xcodebuild -project Example/SPM/Demo.xcodeproj -scheme DemoSPM -destination 'generic/platform=iOS Simulator' -derivedDataPath "$TASK_BUILD_DIR/SPM" build-for-testing CODE_SIGNING_ALLOWED=NO > "$TASK_BUILD_DIR/spm.log" 2>&1
xcodebuild -workspace Example/CocoaPods/Demo.xcworkspace -scheme DemoCocoaPods -destination 'generic/platform=iOS Simulator' -derivedDataPath "$TASK_BUILD_DIR/Pods" build-for-testing CODE_SIGNING_ALLOWED=NO > "$TASK_BUILD_DIR/pods.log" 2>&1
python3 scripts/check_storyboard.py "$TASK_BUILD_DIR/SPM/Build/Products/Debug-iphonesimulator/DemoSPM.app"
python3 scripts/check_storyboard.py "$TASK_BUILD_DIR/Pods/Build/Products/Debug-iphonesimulator/DemoCocoaPods.app"
echo 'SPM、CocoaPods 演示和测试编译通过；UIKit 测试尚未执行。'
