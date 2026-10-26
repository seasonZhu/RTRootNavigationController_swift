Pod::Spec.new do |s|
  s.name = 'RTRootNavigationController_Swift'
  s.version = '1.0.0'
  s.summary = '每个页面拥有独立导航栏的 Swift 导航容器'
  s.description = '纯 Swift 实现独立导航栏、透明导航栈、自定义返回与交互式转场。'
  s.homepage = 'https://github.com/seasonZhu/RTRootNavigationController_Swift'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = { 'seasonZhu' => '17600026862@163.com' }
  s.source = { :git => 'https://github.com/seasonZhu/RTRootNavigationController_Swift.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_versions = ['5.9']
  s.source_files = 'Sources/RTRootNavigationController_Swift/**/*.swift'
  s.frameworks = 'UIKit'
end
