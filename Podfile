source 'https://cdn.cocoapods.org/'
source 'https://github.com/wemap/cocoapods-specs.git'

workspace 'WemapExamples.xcworkspace'

use_frameworks!

platform :ios, '11.0'

#################################################################################

abstract_target 'Map' do

  pod 'WemapMapSDK', '~>0.11.0'

  pod 'NAOSwiftProvider', :git => 'git@github.com:wemap/NAOSwiftProvider.git', :tag => '1.2.2'
  pod 'WemapPositioningSDKPolestar', '~>0.11.0'

  target 'MapExample'

  target 'Map+PositioningExample' do
    pod 'WemapPositioningSDK/VPSARKit', '~>0.11.0'
  end
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
      end
    end
  end
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
