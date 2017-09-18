//
//  Spotify Authentication Framework.h
//  Spotify Authentication Framework
//
//  Created by Dmytro Ankudinov on 26/09/16.
//  Copyright © 2016 Spotify AB. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Spotify Authentication Framework.
FOUNDATION_EXPORT double SpotifyAuthenticationVersionNumber;

//! Project version string for Spotify Authentication Framework.
FOUNDATION_EXPORT const unsigned char SpotifyAuthenticationVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Spotify/PublicHeader.h>

#import <Spotify/SPTAuth.h>
#import <Spotify/SPTSession.h>

#if TARGET_OS_IPHONE
#import <Spotify/SPTConnectButton.h>
#import <Spotify/SPTAuthViewController.h>
#import <Spotify/SPTStoreViewController.h>
#import <Spotify/SPTEmbeddedImages.h>
#endif


