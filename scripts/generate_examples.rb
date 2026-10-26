#!/usr/bin/env ruby
# 从共用 Swift 场景生成两种独立集成工程。
require 'xcodeproj'
require 'fileutils'
root = File.expand_path('..', __dir__)
%w[SPM CocoaPods].each do |integration|
  directory = File.join(root, 'Example', integration)
  project = Xcodeproj::Project.new(File.join(directory, 'Demo.xcodeproj'))
  app = project.new_target(:application, "Demo#{integration}", :ios, '13.0')
  tests = project.new_target(:unit_test_bundle, "Demo#{integration}Tests", :ios, '13.0')
  tests.add_dependency(app)
  group = project.main_group.new_group('Shared')
  Dir.glob(File.join(root, 'Example/Shared/*.swift')).sort.each do |path|
    app.source_build_phase.add_file_reference(group.new_file(Pathname.new(path).relative_path_from(Pathname.new(directory)).to_s))
  end
  resources = project.main_group.new_group('Resources')
  app.resources_build_phase.add_file_reference(resources.new_file('../Resources/UnwindFixture.storyboard'))
  test_group = project.main_group.new_group('Tests')
  Dir.glob(File.join(root, 'Tests/RTRootNavigationControllerTests/*.swift')).sort.each do |path|
    tests.source_build_phase.add_file_reference(test_group.new_file(Pathname.new(path).relative_path_from(Pathname.new(directory)).to_s))
  end
  tests.resources_build_phase.add_file_reference(resources.new_file('../Resources/UnwindFixture.storyboard'))
  [app, tests].each do |target|
    target.build_configurations.each do |configuration|
      settings = configuration.build_settings
      settings['SWIFT_VERSION'] = '5.0'
      settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      settings['TARGETED_DEVICE_FAMILY'] = '1,2'
      settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.seasonzhu.rtnavigation.#{target.name}"
      settings['GENERATE_INFOPLIST_FILE'] = 'YES'
      settings['CODE_SIGN_STYLE'] = 'Automatic'
      settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) ' + (integration == 'CocoaPods' ? 'DEMO_COCOAPODS' : 'DEMO_SPM')
      settings['CLANG_ENABLE_MODULES'] = 'YES'
    end
  end
  app.build_configurations.each do |configuration|
    configuration.build_settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
    configuration.build_settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
    configuration.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
  end
  tests.build_configurations.each do |configuration|
    configuration.build_settings['TEST_HOST'] = "$(BUILT_PRODUCTS_DIR)/#{app.name}.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/#{app.name}"
    configuration.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  end
  if integration == 'SPM'
    reference = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
    reference.relative_path = '../..'
    project.root_object.package_references << reference
    [app, tests].each do |target|
      dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
      dependency.product_name = 'RTRootNavigationController_Swift'
      target.package_product_dependencies << dependency
      build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      build_file.product_ref = dependency
      target.frameworks_build_phase.files << build_file
    end
  end
  project.save
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(app)
  scheme.add_test_target(tests)
  scheme.set_launch_target(app)
  scheme.save_as(project.path, app.name, true)
end
