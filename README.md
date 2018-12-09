# AQOO
## udacity.com student submission

[![Udacity Course Id](https://img.shields.io/badge/udacity-ND003-37C6EE.svg)](UDACITY)
[![Software License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)
[![APP Version (current)](https://img.shields.io/badge/version-1.0.0-blue.svg)](VERSION)
[![Language](https://img.shields.io/badge/swift-4.2-orange.svg)](http://swift.org)

*This repository contains the project submission for my udacity.com final project work "AQOO" during my iOS developer certification program (course ND003).*

## App Description

„AQOO“ (AQ) is an iOS 11 mobile app that allows users to manage and listen their [spotify](http://spotify.com/) playlists. This app using the 0.27.n spotify sdk/api framework including some nice improvements like dedicated list sorting mechanics and better rating options.

## App Specifications

- AQOO (currently 1.0.0) was developed using the latest XCode 9.4.1 (9F2000) build and will be able to run under iOS version 11.4 up to the latest iOS version 12.1 (16B92) 

- AQOO is using POD composition technics to handle 3rd party dependencies. You have to install [POD](https://guides.cocoapods.org/using/getting-started.html) 
and run ```pod install``` on your console before starting the app as your XCode workspace.

- AQOO uses multiple API endpoints by [spotifies iOS SDK](https://developer.spotify.com/documentation/web-api/quick-start/) webAPI-wrapper.

- AQOO uses 3rd Party Libraries for better UX/UI behavior and graphical elements from icons8. A complete list of used libraries and assets can be found inside the projects [COPYRIGHT.md](COPYRIGHT.md) file.

## App Requirements

AQOO uses a dedicated Spotify-API-Access-KeyPair (spfClientSecret, spfClientId) including a valid Callback-URL that must be provided by yourself (e.g. ```aqoo://``` for this project) and has to provided into a Keys.plist file using the corresponding spfClient-KeyIds. Please create this file first and add the KeyValues generated from spotifies developer app  [registration formular](https://developer.spotify.com/documentation/general/guides/app-settings/#register-your-app) later. 

![Keys.plist file](github/media/aq_keys_plist.jpg) 

AQOO needs a valid spotify premium account to authenticate yourself and gain access to your personal playlist information. Unfortunately spotify free-accounts are currently not supported by this app.

## App Features

AQOO manage your complete spotify playlist stack and extend some origin meta information by additional functionality and statistics. All playlists and Tracks handled by this app will stored as dedicated data into your device and leave your origin meta source on spotify untouched. You can rename, rate, tag and add detailed notes to your playlists. You also can switch playlist cover images by your own without touching your origin dataset at spotify.

AQOO playback your playlists in different modes (normal, repeat and shuffle). You can start playing your lists directly from the corresponding list or from our tracklist view. The player controls are more suffisticated inside the tracklist view - here you can jump between tracks or traveling inside the timeframe of current song played.

AQOO helps you filtering your playlist by your own provided list rating, owner, most-frequently heard or by track count. Additional filter will be provided with next version of this app (see „App Future“ section). You will also be able to „hide“ some playlists from your main stack - those playlists will be available selecting your „my hidden playlist“ filter option. You can always (re)enable those playlists from that view later.

*For details about application functions and features take a look into our screenshot sections down below*.

## App Structure

AQOO is following the MVC pattern by structural and logical definition. The app is using dedicated view partials instead of base sub views of collection cells and annotations. This app also using async handlers and event observer to provide better performance during long term execution of processes. 

![xcode project structure](github/media/aq_code_01.jpg) 

## App Start

After starting the app and the launch screen disapears a login view will allow to identify yourself using your spotify credentials. *Please take note, that you’ll require a premium spotify account to use AQOO.*

Splash Screen | Login Screen | Spotify Login | Spotify Auth
:-------------------------:|:-------------------------:|:-------------------------:|:-------------------------:
![splash screen](github/media/small/aq_launch_01.png)  |  ![login view](github/media/small/aq_login_01.png) | ![spotify login](github/media/small/aq_spotify_login_01.png)  |  ![spotify auth](github/media/small/aq_spotify_auth_02.png)

##  Your Playlist View

After authentication the app will provide you a tableView with all your spotify playlists available. Here you can filter, edit, hide using background cell controls or open a more detailed cell-view for each entry. *You can also jump from selected playlist into tracklist view directly*.

Playlist View | Playlist Cell Controls | Playlist Cell Details 
:-------------------------:|:-------------------------:|:-------------------------:
![normal playlist view](github/media/small/aq_playlist_04.png) |  ![playlist cell controls](github/media/small/aq_playlist_03.png) | ![playlist cell details](github/media/small/aq_playlist_02.png)

## Your Playlist Edit View

You can configure your playlist by editing base information like title and description furthermore you can add tags to help categorize you list  and [rate you playlist](https://www.digitalmusicnews.com/2016/05/17/music-genres-three-attributes/) using three different meta values (intensity, emotivness and depth).

Playlist Edit View | Playlist Rating View | Playlist Meta Edit View
:-------------------------:|:-------------------------:|:-------------------------:
![main edit view](github/media/small/aq_playlist_edit_01.png) |  ![rating view](github/media/small/aq_playlist_edit_02.png) | ![playlist details view](github/media/small/aq_playlist_edit_03.png)

## Your Tracklist View

From each playlist entry you can switch to the corresponding tracklist and start playling in shuffle-, repeat- or normal mode. While the track is playing there are additional controls available such as jump between tracks and skipping forward or backward inside the track using the timeframe slider. *In general you can switch between two main views for your playlists stack - the normal table based view and the playlist cover view*. 

Tracklist View | Tracklist Playback | Playlist Cover View
:-------------------------:|:-------------------------:|:-------------------------:
![normal tracklist](github/media/small/aq_tracklist_01.png) |  ![playmode active](github/media/small/aq_tracklist_02.png) | ![playlist cover view](github/media/small/aq_coverlist_01.png)

## Keywords
swift, swift-4, udacity, extension, uikit, foundation, app, spotify, spotify-sdk, streaming, music, player, streams

## Releases

AQQO is currently available in [3 releases](https://github.com/paterik/udacity-ios-virtual-tourist/releases) and will be following the sequence-based semantic version pattern _major.minor.patch_.

## Changelog

All notable changes of the AQOO release series are documented in project [CHANGELOG.md](CHANGELOG.md) file using the [Keep a CHANGELOG](http://keepachangelog.com/) principles. The changelog documentation starts with version 0.9.9 (2017-09-18).

## License-Term

Copyright (c) 2017-2018 Patrick Paechnatz <patrick.paechnatz@gmail.com>
                                                                           
Permission is hereby granted,  free of charge,  to any  person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction,  including without limitation the rights to use,  copy, modify, merge, publish,  distribute, sublicense, and/or sell copies  of the  Software,  and to permit  persons to whom  the Software is furnished to do so, subject to the following conditions:       
                                                                           
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
                                                                           
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING  BUT NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR  PURPOSE AND  NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,  WHETHER IN AN ACTION OF CONTRACT,  TORT OR OTHERWISE,  ARISING FROM,  OUT OF  OR IN CONNECTION  WITH THE  SOFTWARE  OR THE  USE OR  OTHER DEALINGS IN THE SOFTWARE.
