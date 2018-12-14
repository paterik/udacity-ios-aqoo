source 'https://github.com/artsy/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.4'
use_frameworks!
inhibit_all_warnings!

# CI was having trouble shipping signed builds
# https://github.com/CocoaPods/CocoaPods/issues/4011

post_install do |installer|

    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ''
            config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
    end
end

def aq_ui
    pod 'BGTableViewRowActionWithImage', '0.4.4'
    pod 'FoldingCell', '3.1.5'
    pod 'SnapKit', '4.0.0'
    pod 'fluid-slider', '0.0.6'
    pod 'GradientLoadingBar', '1.1.11'
    pod 'Persei', '3.1'
    pod 'PKHUD', '5.2.0'
    pod 'WSTagsField', '3.2.0'
    pod 'MaterialComponents/ProgressView', '70.1.0'
    pod 'NotificationBannerSwift', '1.6.3'
    pod 'MarqueeLabel/Swift', '3.1.6'
end

def aq_base
    pod 'Spotify-iOS-SDK', '0.27.0', :modular_headers => true
    pod 'CryptoSwift', '0.11.0'
    pod 'Kingfisher', '5.0.0'
    pod 'LetterAvatarKit', '1.1.5'
    pod 'SwiftRandom', '1.0.0'
    pod 'SwiftDate', '5.0.7'
end

def aq_data
    pod 'CoreStore', '5.2.0'
end

def aq_system
    pod 'ReachabilitySwift', '4.3.0'
end

target 'aqoo' do
    aq_ui
    aq_base
    aq_data
    aq_system
end
