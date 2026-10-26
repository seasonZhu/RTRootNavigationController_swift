#!/usr/bin/env python3
"""验证已编译的 Storyboard 场景、页面类和 unwind 连接，避免空资源误判。"""
from pathlib import Path
import plistlib
import sys

bundle = Path(sys.argv[1]) / 'UnwindFixture.storyboardc'
with (bundle / 'Info.plist').open('rb') as source:
    info = plistlib.load(source)
assert info.get('UIStoryboardDesignatedEntryPointIdentifier'), '缺少初始导航场景'
assert len(info.get('UIViewControllerIdentifiersToNibNames', {})) >= 2, '缺少详情场景'
resources = list(bundle.glob('*.nib'))
assert len(resources) >= 4, '缺少控制器或页面视图资源'
data = b''.join(path.read_bytes() for path in resources)
for name in [b'StoryboardRootController', b'StoryboardDetailController', b'returnToRoot:', b'RTRootNavigationController']:
    assert name in data, f'缺少场景类或连接：{name!r}'
print(f'Storyboard 场景与 unwind 连接检查通过：{bundle}')
