//
//  PlaylistViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 20.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import CryptoSwift

extension PlaylistViewController {
    
    @objc func setupUILoadPlaylist() {
        
        print ("\nI've found \(_playlistsInCloud.count) playlists for current user\n")
        print ("==\n")
        for (index, item) in _playlistsInCloud.enumerated() {
            print ("list: #\(index)")
            print ("name: \(item.name!), \(item.trackCount) songs")
            print ("uri: \(item.playableUri!)")
            print ("\n--\n")
        }
        
        // store playlist in db
        
        tableView.reloadData()
    }
    
    func setupUIMainMenuView() { }
    
    func setupUITableView() {
    
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func handleNewUserPlaylistSession() {
        
        // load spotify default provider tag (spotify)
        synchronizePlaylists( _defaultStreamingProviderTag )
    }
    
    func _handlePlaylistGetNextPage(_ currentPage: SPTListPage, _ accessToken: String) {
        
        currentPage.requestNextPage(
            
            withAccessToken: accessToken,
            callback: {
                
               ( error, response ) in
                
                if  let _nextPage = response as? SPTListPage,
                    let _playlists = _nextPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlistsInCloud.append(contentsOf: _playlists)
                    
                    // check for additional subPages
                    if _nextPage.hasNextPage == false {
                        // no further entries in pagination? send completed call!
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
                            object: self
                        )
                        
                    } else { self._handlePlaylistGetNextPage(_nextPage, accessToken) }
                }
            }
        )
    }
    
    func _handlePlaylistGetFirstPage(_ username: String, _ accessToken: String) {
        
        SPTPlaylistList.playlists(
            
            forUser: username,
            withAccessToken: accessToken,
            callback: {
                
               ( error, response ) in
                
                if  let _firstPage = response as? SPTPlaylistList,
                    let _playlists = _firstPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlistsInCloud = _playlists
                    
                    // check for additional pages
                    if _firstPage.hasNextPage == false {
                        // no further entries in pagination? send completed call!
                        NotificationCenter.default.post(
                            name: NSNotification.Name.init(rawValue: self.appDelegate.spfSessionPlaylistLoadCompletedNotifierId),
                            object: self
                        )
                        
                    } else { self._handlePlaylistGetNextPage(_firstPage, accessToken) }
                }
            }
        )
    }
    
    func loadPlaylists (_ provider: CoreStreamingProvider) {

        let providerName = provider.name
        
        print ("_ load cached playlists for provider [\(providerName)]")
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> [StreamPlayList]? in
    
                self._defaultStreamingProvider = provider
                
                return transaction.fetchAll(
                    From<StreamPlayList>(),
                    Where("provider", isEqualTo: provider) &&
                    Where("owner", isEqualTo: self.appDelegate.spfUsername)
                )
            },
            
            success: { (transactionPlaylists) in
                
                if transactionPlaylists?.isEmpty == false {
                    
                    print ("_ some playlist data for provider [\(providerName)] available ...")
                    
                    // store database fetch results in cache collection
                    self._playlistsInDb = transactionPlaylists!
                    
                } else {
                    
                    print ("_ no cached playlist data for provider [\(providerName)] found ...")
                    
                    // clean previously cached playlist collection
                    self._playlistsInDb = []
                }
                
                // always fetch new playlists from api for upcoming sync
                self._handlePlaylistGetFirstPage(
                    self.appDelegate.spfUsername,
                    self.appDelegate.spfCurrentSession!.accessToken!
                )
            },
            
            failure: { (error) in
                self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! An error occured while loading provider from database ...")
            }
        )
    }
    
    func _getPlayListFromDbByHash(_ hash: String) -> StreamPlayList? {
        
        for playList in _playlistsInDb {
            
            if playList.metaListHash == hash {
                return playList
            }
        }
        
        return nil
    }
    
    func synchronizePlaylists(_ provider: String) {
        
        print ("_ try to synchronize playlists for provider [\(provider)] ...")
        
        loadProvider ( provider )
        
        for playListInCloud in _playlistsInCloud {
            
            print ("-> \(playListInCloud.playableUri)")
            
         
            // 1.) check for hashed uri as identifier for both (equal) entries / local- and remote list
            if let playListInDb = _getPlayListFromDbByHash( playListInCloud.playableUri.absoluteString.md5() ) {
            
                print ("_ found db counterPart of [\(playListInCloud.getMD5FingerPrint())] in DB as [\(playListInDb.getMD5FingerPrint())]")
                
                // 2.) check for fingerprint changeSet in local playlist
                if validateListForChanges(playListInDb, playListInCloud) == true {
                
                    // 3.) update local playlist by primary propertySets (name, trackCount, isPublic and isCollaborative)
                    CoreStore.perform(
                        asynchronous: { (transaction) -> Void in
                            let _playlist = transaction.fetchOne(
                                 From<StreamPlayList>(),
                                 Where("metaListHash", isEqualTo: playListInDb.metaListHash)
                            )
                            
                            if  _playlist != nil {
                                _playlist!.name = playListInCloud.name
                                _playlist!.trackCount = Int64(playListInCloud.trackCount)
                                _playlist!.isCollaborative = playListInCloud.isCollaborative
                                _playlist!.isPublic = playListInCloud.isPublic
                                _playlist!.metaNumberOfUpdates += 1
                                _playlist!.updatedAt = Date()
                            }
                        },
                        completion: { _ in }
                    )
                }
                
            } else {
                
                print ("_ no counterPart of [\(playListInCloud.getMD5FingerPrint())] found in db")
                
            }
        }
    }
    
    func validateListForChanges(
       _ playListInDb: StreamPlayList,
       _ playListInCloud: SPTPartialPlaylist) -> Bool {

        return playListInDb.getMD5FingerPrint() != playListInCloud.getMD5FingerPrint()
    }
    
    func loadProvider (_ tag: String) {
        
        print ("_ try to load provider [\(tag)]")
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> CoreStreamingProvider? in
                return transaction.fetchOne(From<CoreStreamingProvider>(), Where("tag", isEqualTo: tag))
            },
            
            success: { (transactionProvider) in
                
                if transactionProvider == nil {
                    self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! No provider were found in database ...")
                }   else {
                    
                    print ("_ provider [\(tag)] successfully loaded, now try to load cached playlists ...")
                    self.loadPlaylists ( transactionProvider! )
                }
            },
            
            failure: { (error) in
                self._handleErrorAsDialogMessage("Error Loading Provider", "Oops! An error occured while loading provider from database ...")
            }
        )
    }
}
