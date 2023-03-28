source 'https://cdn.cocoapods.org/'
source 'https://github.com/wemap/cocoapods-specs.git' 

workspace 'WemapExamples.xcworkspace'

use_frameworks!

platform :ios, '11.0'

#################################################################################

target 'MapExamples' do
  pod 'WemapMapSDK', '~>0.1.0'
  pod 'NAOSwiftProvider', :git => 'git@github.com:wemap/NAOSwiftProvider.git', :tag => '1.2.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end