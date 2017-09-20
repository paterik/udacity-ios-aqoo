source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
use_frameworks!

def aq_ui
    pod 'BGTableViewRowActionWithImage'
    pod 'YNDropDownMenu'
    pod 'FoldingCell'
    pod 'Hero'
    pod 'SCLAlertView'
    pod 'SnapKit', '~> 3.2.0'
end

def aq_base
    pod 'CryptoSwift', '<= 0.6.9'
    pod 'Kingfisher', '~> 3.0'
    pod 'Spotify-iOS-SDK'
end

def aq_data
    pod 'CoreStore', '~> 4.0'
end

target 'aqoo' do
    aq_ui
    aq_base
    aq_data
end
