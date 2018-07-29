source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

def aq_ui
    pod 'BGTableViewRowActionWithImage'
    pod 'FoldingCell'
    pod 'SnapKit'
    pod 'fluid-slider'
    pod 'GradientLoadingBar'
    pod 'Persei', '~> 3.0'
    pod 'PKHUD', '~> 5.0'
    pod 'WSTagsField', '~> 3.1'
    pod 'NotificationBannerSwift'
end

def aq_base
    pod 'CryptoSwift'
    pod 'Kingfisher'
    pod 'Spotify-iOS-SDK'
    pod 'LetterAvatarKit'
    pod 'Reachability'
    pod 'SwiftRandom'
    pod 'SwiftDate', '~> 5.0'
end

def aq_data
    pod 'CoreStore'
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
end
