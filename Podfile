source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

def aq_ui
    pod 'BGTableViewRowActionWithImage', '0.4.4'
    pod 'FoldingCell', '3.1.4'
    pod 'SnapKit', '4.0.1'
    pod 'fluid-slider', '0.0.6'
    pod 'GradientLoadingBar', '1.1.11'
    pod 'Persei', '~> 3.0'
    pod 'PKHUD', '5.2.0'
    pod 'WSTagsField', '3.2.0'
    pod 'NotificationBannerSwift', '1.6.3'
    pod 'MaterialComponents/ProgressView'
end

def aq_base
    pod 'Spotify-iOS-SDK'
    pod 'CryptoSwift', '0.12.0'
    pod 'Kingfisher', '4.8.1'
    pod 'LetterAvatarKit', '1.1.5'
    pod 'Reachability', '3.2'
    pod 'SwiftRandom', '1.0.0'
    pod 'SwiftDate', '5.0.9'
end

def aq_data
    pod 'CoreStore', '5.2.0'
end

target 'aqoo' do
    aq_ui
    aq_base
    aq_data
end

post_install do |installer|

    podsTargets = installer.pods_project.targets.find_all { |target| target.name.start_with?('Pods') }
    podsTargets.each do |target|
        target.frameworks_build_phase.clear
    end

    installer.pods_project.build_configurations.each do |config|

        # Workaround for CocoaPods issue: https://github.com/CocoaPods/CocoaPods/issues/7606
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')

        # Do not need debug information for pods
        config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'

        # Disable Code Coverage for Pods projects - only exclude ObjC pods
        config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
        config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(FRAMEWORK_SEARCH_PATHS)']

        config.build_settings['SWIFT_VERSION'] = '4.0'
  end
end
