source 'https://cdn.cocoapods.org/'
source 'https://github.com/wemap/cocoapods-specs.git'

workspace 'WemapExamples.xcworkspace'

use_frameworks!

platform :ios, '13.0'

#################################################################################

wemap_sdks_version = '~>0.25.1'

target 'MapExample' do
  pod 'WemapMapSDK', wemap_sdks_version
end

target 'Map+PositioningExample' do
  pod 'WemapMapSDK', wemap_sdks_version
  
  pod 'WemapPositioningSDK/Polestar', wemap_sdks_version
  pod 'WemapPositioningSDK/VPSARKit', wemap_sdks_version
end

target 'PositioningExample' do
  pod 'WemapPositioningSDK/VPSARKit', wemap_sdks_version
end

target 'Positioning+ARExample' do

  pod 'WemapGeoARSDK', wemap_sdks_version
  
  pod 'WemapPositioningSDK/GPS', wemap_sdks_version
  pod 'WemapPositioningSDK/VPSARKit', wemap_sdks_version
end


#################################################################################

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
  end
end
