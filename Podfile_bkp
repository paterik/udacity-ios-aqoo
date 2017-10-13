source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.3'
use_frameworks!
inhibit_all_warnings!

def aq_ui
    pod 'BGTableViewRowActionWithImage'
    pod 'FoldingCell'
    pod 'SnapKit'
end

def aq_base
    pod 'CryptoSwift'
    pod 'Kingfisher', '~> 4.0.1'
    pod 'Spotify-iOS-SDK'
    pod 'Reachability'
end

def aq_data
    pod 'CoreStore', :git => 'https://github.com/JohnEstropia/CoreStore.git', :branch => 'prototype/Swift_4_0'
end

target 'aqoo' do
    aq_ui
    aq_base
    aq_data
end
