# AQOO
## udacity.com student submission

[![Udacity Course Id](https://img.shields.io/badge/udacity-ND003-37C6EE.svg)](UDACITY)
[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![APP Version (latest stable)](https://img.shields.io/badge/version-1.0.5-blue.svg)](VERSION)
[![Language](https://img.shields.io/badge/swift-4.2.1-orange.svg)](https://swift.org)
[![IDE](https://img.shields.io/badge/xcode-10.1-lightblue.svg)](https://itunes.apple.com/us/app/xcode/id497799835?ls=1&mt=12)
[![Build Status](https://travis-ci.org/paterik/udacity-ios-aqoo.svg?branch=master)](https://travis-ci.org/paterik/udacity-ios-aqoo)

*This repository contains the project submission for my udacity.com final project work "AQOO" during my iOS developer certification program (course ND003).*

## App Description

„AQOO“ („A-Q“) is an iOS 11 mobile app that allows users to manage and listen their [spotify](http://spotify.com/) playlists. This app uses the classic 0.27.0 spotify sdk/api iOS framework including some major improvements like dedicated list sorting mechanics, advanced shuffle playmode and advanced rating options.

## App Specifications

- AQOO was developed using the latest XCode 10.1 (10B61) build and is able to run under iOS version 11.4 up to the latest iOS version 12.1 (16B92) 

- AQOO is using POD composition technics to handle 3rd party dependencies. You have to install [POD](https://guides.cocoapods.org/using/getting-started.html) 

- AQOO uses multiple API endpoints of [Spotify-Streaming-SDK](https://spotify.github.io/ios-streaming-sdk/) webAPI-wrapper. An internet connection is required for login, track-/playlist-sync and streaming of all of your tracks.

- AQOO uses 3rd Party Libraries for better UX/UI behavior and graphical elements from [icons8](https://icons8.de/). A complete list of used libraries and assets can be found in the [COPYRIGHT.md](COPYRIGHT.md) file.

 *more detailed/build related information can be obtained in the ```App Build Process``` section of this documentation*

## App Build Process

To build this app you’ve to take care of the following steps.

1. Checkout this repository on your system. I suggest using the smaller [shallow clone mechanic](https://www.perforce.com/blog/git-beyond-basics-using-shallow-clones) for this process.

```
git clone git@github.com:paterik/udacity-ios-aqoo.git --depth 1
```

2. Install [POD](https://guides.cocoapods.org/using/getting-started.html) on your system and load all libs required (do NOT use ```pod install```)

```
cd <your_project_path> ; pod update
```

3. Load project workspace ```aqoo.xcworkspace``` in your XCode 10.1 IDE and ensure your toolchain is set to XCode 10 internal or the currently supported Swift 4.2.1 and may clean up your previous build artifacts using <Product/clean>

ToolChain Setup | Build CleanUp
:-------------------------:|:-------------------------:
![ToolChain Config](github/media/xcode_tc_setup_10_marks.jpg)  |  ![Build CleanUp](github/media/xcode_prep_cw.jpg)

5. Add a new property list (plist) file into your project resource group, named this file ```Keys.plist``` and insert the two required keys ```spfClientId``` and ```spfClientCallbackURL``` for APP/SpotifyAPI authentication. Generate the corresponding values for this keys from spotifies developer app  [registration formular](https://developer.spotify.com/documentation/general/guides/app-settings/#register-your-app). You can find a dedicated tuturial for this process at [medium.com](https://medium.com/@brianhans/getting-started-with-the-spotify-ios-sdk-435607216ecc). I recommend to switch to the new build system of XCode (*Select File -> Project/Workspace Setting*)

Keys.plist Config | New Build System Config
:-------------------------:|:-------------------------:
![Keys.plist file](github/media/aq_keys_plist_marks.jpg)   | ![XCode NBS](github/media/xcode_10_ws_settings.jpg) 

6. Compile/build the app using one of your favorite device simulators. This app ist optimized for iphone mobile device classes but should also be runnable using bigger screen devices like iPads. 

![Build State](github/media/xcode_10_build_done.jpg) 

*You can execute the commandline-based build process (please close XCode 10.1 first) using the following command:*

```
xcodebuild clean build -workspace aqoo.xcworkspace -scheme aqoo -destination "platform=iOS Simulator,name=iPhone 6s" -sdk iphonesimulator -toolchain XCode10.1 -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ONLY_ACTIVE_ARCH=YES
```

*To run application unit tests locally, use the following command:*

```
xcodebuild clean build-for-testing test -workspace aqoo.xcworkspace -scheme aqoo -destination "platform=iOS Simulator,name=iPhone 6s" -sdk iphonesimulator -toolchain XCode10.1 -configuration Debug CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO ONLY_ACTIVE_ARCH=YES
```

## App Requirements

AQOO needs a valid spotify premium account to authenticate and gain access to your personal playlist information. *Unfortunately spotify free-accounts are currently not supported by this app*.

## App Features

AQOO manages your complete spotify playlist stack and extends some origin meta information by additional functionality and statistics. All playlists and Tracks handled by this app will be stored as dedicated data sets on your mobile device and leave your origin meta source on spotify untouched. You can rename, rate, tag and add detailed notes to your playlists. You also can switch playlist cover images with your own without touching the original dataset at spotify.

AQOO can play your playlists in different modes (normal, repeat and shuffle). You can start playing your lists directly from the corresponding list or from the tracklist view (for normal playmode). The player controls are more sophisticated inside the tracklist view - here you can jump between all tracks or directly in the timeframe of the  current song. In this view all of our playmodes are fully supported.

AQOO helps you filtering your playlist by providing an additional list rating. You can also filter by owner, most-frequently heard or by track count. You can also „hide“ some playlists from your main stack - those playlists will be available again by selecting your „my hidden playlist“ filter option. You can always (re)enable those playlists from that view later.

*For details about application functions and features take a look into our screenshot sections down below*.

## App Structure

AQOO is following the MVC pattern by structural and logical definition. The app is using dedicated view partials instead of base sub views of collection cells and annotations. This app also uses async handlers and event observers to provide better performance during long term execution of internal processes. 

![xcode project structure](github/media/aq_code_01.jpg) 

## App Start

After starting the app and the launch screen disappears a login view will allow to identify yourself using your spotify credentials. *Please take note that you’ll require a premium spotify account to use AQOO.*

Splash Screen | Login Screen | Spotify Login | Spotify Auth
:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:
![splash screen](github/media/small/aq_launch_01.png)  |  ![login view](github/media/small/aq_login_01.png) | ![spotify login](github/media/small/aq_spotify_login_01.png)  |  ![spotify auth](github/media/small/aq_spotify_auth_02.png)

##  App Playlist View

After authentication the app will provide you a tableView with all your spotify playlists available. Here you can filter, edit and hide playlists using background cell controls or open a more detailed cell-view for each entry. *You can also jump from selected playlist into tracklist view directly*.

Playlist View | Playlist Cell Controls | Playlist Cell Details 
:-------------------------:|:-------------------------:|:-------------------------:
![normal playlist view](github/media/small/aq_playlist_04.png) |  ![playlist cell controls](github/media/small/aq_playlist_03.png) | ![playlist cell details](github/media/small/aq_playlist_02.png)

## App Playlist Edit View

You can configure your playlist by editing base information like title and description. Furthermore you can add tags to help categorize your list  and [rate your playlist](https://www.digitalmusicnews.com/2016/05/17/music-genres-three-attributes/) using three different meta values (intensity, emotivness and depth).

Playlist Edit View | Playlist Rating View | Playlist Meta Edit View
:-------------------------:|:-------------------------:|:-------------------------:
![main edit view](github/media/small/aq_playlist_edit_01.png) |  ![rating view](github/media/small/aq_playlist_edit_02.png) | ![playlist details view](github/media/small/aq_playlist_edit_03.png)

## App Tracklist View

From each playlist entry you can switch to the corresponding tracklist and start playing in shuffle-, repeat- or normal mode. While the track is playing there are additional controls available such as jump between tracks and skipping forward or backward inside the track using the timeframe slider. *In general you can switch between two main views for your playlists stack - the normal table based view and the playlist cover view*. 

Tracklist View | Tracklist Playback | Playlist Cover View
:-------------------------:|:-------------------------:|:-------------------------:
![normal tracklist](github/media/small/aq_tracklist_01.png) |  ![playmode active](github/media/small/aq_tracklist_02.png) | ![playlist cover view](github/media/small/aq_coverlist_01.png)

## Known Issues

* The build process could break if you’re not using the latest XCode 10.1 version and the corresponding Swift binary set in version 4.2.1 - please ensure, that you’re using the right ToolChain and XCode version for this project. If the build is still failing, check the current workspace settings - enforce „New Build System“ setup for XCode (there is an article about this on [medium.com](https://medium.com/xcblog/xcode-new-build-system-for-speedy-swift-builds-c39ea6596e17)). You can also try to clean the ```./Pods/*``` directory and enforce a complete cache clean for pod using ```pod cache clean --all``` followed by a fresh update/install of all required libs ```pod update```.

* The cover image handler has changed on 2018-12-09 based on major changes of the current Spotify API endpoint - so I’ve decide to take an image from the corresponding tracklist instead of the origin cover image. *This will be changed as soon as I extend the current API structure*. 

* The cover image cache for the playlists may take a bit time to display the identified images in our table cells - after view refresh process (by scrolling in your playlist items or leaving this view and returning) all covers should be visible.

* The application will show ```client_id missing``` error if your Keys.plist file hasn’t complete or invalid value sets - please ensure, that you provide all neccessary values to your ```Keys.plist``` file. You’ve to request a valid ```client_id```and your application ```callback_url``` from [spotify/developer](https://developer.spotify.com/documentation/general/guides/app-settings/#register-your-app) app registration page. 

* The Spotify-Streaming-SDK used in the project will no longer maintained by spotify - furthermore some of the core functions are currently under heavy refactoring/changes. I’ll try to provide a own iOS-webAPI-wrapper as functional base for this application and provide the code here on github as opensource within the next month.

## Keywords

ios, iphone, swift, swift-4, udacity, uikit, foundation, app, spotify, spotify-sdk, streaming, music, player, streams

## Releases

AQQO is currently available in [7](https://github.com/paterik/udacity-ios-aqoo/releases) releases and will be following the sequence-based semantic version pattern _major.minor.patch_. The latest stable version of this app is ```1.0.5``` provided on ```2018-12-15```.

## Changelog

All notable changes of the AQOO release series are documented in project [CHANGELOG.md](CHANGELOG.md) file using the [Keep a CHANGELOG](http://keepachangelog.com/) principles. The changelog documentation starts with version 0.0.1 (2017-07-18).

## License-Term

Copyright (c) 2017-2018 Patrick Paechnatz <patrick.paechnatz@gmail.com>
                                                                           
Permission is hereby granted,  free of charge,  to any  person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction,  including without limitation the rights to use,  copy, modify, merge, publish,  distribute, sublicense, and/or sell copies  of the  Software,  and to permit  persons to whom  the Software is furnished to do so, subject to the following conditions:       
                                                                           
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                                                                           
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING  BUT NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR  PURPOSE AND  NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,  WHETHER IN AN ACTION OF CONTRACT,  TORT OR OTHERWISE,  ARISING FROM,  OUT OF  OR IN CONNECTION  WITH THE  SOFTWARE  OR THE  USE OR  OTHER DEALINGS IN THE SOFTWARE.
