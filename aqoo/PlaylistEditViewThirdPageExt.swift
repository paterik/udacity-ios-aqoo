//
//  PlaylistEditViewThirdPageExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 17.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import Spotify
import CoreStore
import Kingfisher

extension PlaylistEditViewThirdPage {
    
    //
    // MARK: Class Setup UI/UX Functions
    //
    
    func setupUIBase() {
        
        // playlist details will always be updateable
        btnSavePlaylistChanges.isEnabled = true
    }
    
    func setupUIPlaylistDetails() {
        
        textFieldPlaylistDetails.text = playListInDb!.metaListInternalDescription
    }
    
    func handlePlaylistStatisticReset() {
        
        CoreStore.defaultStack.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>().where(\.metaListHash == self.playListInDb!.metaListHash))
                    as? StreamPlayList else {
                        self.handleErrorAsDialogMessage(
                            "Cache Error", "unable to fetch playlist from local cache"
                        );   return
                }
                
                playlistToUpdate.metaNumberOfPlayed = 0
                playlistToUpdate.metaNumberOfShares = 0
                playlistToUpdate.metaNumberOfPlayed = 0
                playlistToUpdate.metaNumberOfPlayedPartly = 0
                playlistToUpdate.metaNumberOfPlayedCompletely = 0
                
                self.playListInDb = playlistToUpdate
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    
                    self.handleErrorAsDialogMessage(
                        "Cache Error", "unable to update playlist local cache"
                    )
                    
                case .success(let userInfo):
                    
                    if  let delegate = self.delegate {
                        delegate.onPlaylistChanged( self.playListInDb! )
                    }
                }
            }
        )
    }
    
    func handlePlaylistMetaUpdate() {
        
        var _playlistDetails: String = textFieldPlaylistDetails.text
        
        CoreStore.defaultStack.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>().where(\.metaListHash == self.playListInDb!.metaListHash))
                    as? StreamPlayList else {
                        self.handleErrorAsDialogMessage(
                            "Cache Error", "unable to fetch playlist from local cache"
                        );   return
                }
                
                playlistToUpdate.updatedAt = Date()
                playlistToUpdate.metaNumberOfUpdates += 1
                playlistToUpdate.metaPreviouslyUpdatedManually = true
                playlistToUpdate.metaListInternalDescription = _playlistDetails
                
                self.playListInDb = playlistToUpdate
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    
                    self.handleBtnSavePlaylistChangesState( active: false )
                    self.handleErrorAsDialogMessage(
                        "Cache Error", "unable to update playlist local cache"
                    )
                    
                case .success(let userInfo):
                    
                    // delegate information about current playlist state to parentView
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if  let delegate = self.delegate {
                        delegate.onPlaylistChanged( self.playListInDb! )
                    }
                }
            }
        )
    }
    
    func handleBtnSavePlaylistChangesState(active: Bool) {
        
        btnSavePlaylistChanges.isEnabled = active
    }
}
