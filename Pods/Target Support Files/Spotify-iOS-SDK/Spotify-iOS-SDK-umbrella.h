#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SpotifyAudioPlayback.h"
#import "SpotifyAuthentication.h"
#import "SpotifyMetadata.h"
#import "SpPlaybackEvent.h"
#import "SPTAlbum.h"
#import "SPTArtist.h"
#import "SPTAudioPlaybackTypes.h"
#import "SPTAudioStreamingController.h"
#import "SPTAudioStreamingController_ErrorCodes.h"
#import "SPTAuth.h"
#import "SPTAuthViewController.h"
#import "SPTBrowse.h"
#import "SPTCircularBuffer.h"
#import "SPTConnectButton.h"
#import "SPTCoreAudioController.h"
#import "SPTDiskCache.h"
#import "SPTDiskCaching.h"
#import "SPTEmbeddedImages.h"
#import "SPTFeaturedPlaylistList.h"
#import "SPTFollow.h"
#import "SPTImage.h"
#import "SPTJSONDecoding.h"
#import "SPTListPage.h"
#import "SPTMetadataTypes.h"
#import "SPTPartialAlbum.h"
#import "SPTPartialArtist.h"
#import "SPTPartialObject.h"
#import "SPTPartialPlaylist.h"
#import "SPTPartialTrack.h"
#import "SPTPlaybackMetadata.h"
#import "SPTPlaybackState.h"
#import "SPTPlaylistList.h"
#import "SPTPlaylistSnapshot.h"
#import "SPTPlaylistTrack.h"
#import "SPTRequest.h"
#import "SPTSavedTrack.h"
#import "SPTSearch.h"
#import "SPTSession.h"
#import "SPTStoreViewController.h"
#import "SPTTrack.h"
#import "SPTTrackProvider.h"
#import "SPTUser.h"
#import "SPTYourMusic.h"

FOUNDATION_EXPORT double SpotifyVersionNumber;
FOUNDATION_EXPORT const unsigned char SpotifyVersionString[];

