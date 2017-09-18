//
//  Spotify Audio Playback Framework.h
//  Spotify Audio Playback Framework
//
//  Created by Dmytro Ankudinov on 27/09/16.
//  Copyright © 2016 Spotify AB. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Spotify Audio Playback Framework.
FOUNDATION_EXPORT double SpotifyAudioPlaybackVersionNumber;

//! Project version string for Spotify Audio Playback Framework.
FOUNDATION_EXPORT const unsigned char SpotifyAudioPlaybackVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Spotify_Audio_Playback_Framework/PublicHeader.h>

#import <Spotify/SPTCircularBuffer.h>
#import <Spotify/SPTCoreAudioController.h>
#import <Spotify/SPTAudioStreamingController.h>
#import <Spotify/SPTAudioStreamingController_ErrorCodes.h>
#import <Spotify/SPTDiskCaching.h>

#if !TARGET_OS_IPHONE
#import <Spotify/SPTCoreAudioDevice.h>
#endif
