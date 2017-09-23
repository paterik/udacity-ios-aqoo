//
//  LandingPageViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify

class LandingPageViewController: BaseViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    @IBOutlet weak var mnuTopStatus: UINavigationItem!
    @IBOutlet weak var btnSpotifyCall: UIButton!
    @IBOutlet weak var btnExitLandingPage: UIBarButtonItem!

    override var prefersStatusBarHidden: Bool { return true }
    var authViewController: UIViewController?
    
    var _playlists = [SPTPartialPlaylist]()
    
    let _player = SPTAudioStreamingController.sharedInstance()
    let _sampleSong: String = "spotify:track:3rkge8kur9i26zpByFKvBu"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        mnuTopStatus.title = "TOKEN INVALID"
        if  isSpotifyTokenValid() {
            mnuTopStatus.title = "CONNECTED"
            
            //
            // test API :: instantiate a new player and bound this player to current userSession
            //
            // * handleNewPlayerSession()
            
            //
            // test API :: instantiate new playlist request
            //
            handleNewUserPlaylistSession()
            
            print("dbg: session => \(appDelegate.spfCurrentSession!.accessToken!)")
            print("dbg: username => \(appDelegate.spfUsername)")
        }
    }
    
    func _handlePlaylistGetNextPage(_ currentPage: SPTListPage, _ accessToken: String) {
    
        currentPage.requestNextPage(
            withAccessToken: accessToken,
            callback: {
                
                (error, response) in
                
                if  let _nextPage = response as? SPTListPage,
                    let _playlists = _nextPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlists.append(contentsOf: _playlists)
                    
                    if _nextPage.hasNextPage {
                        self._handlePlaylistGetNextPage(_nextPage, accessToken)
                    }
                }
            }
        )
    }
    
    func _handlePlaylistGetFirstPage(_ username: String, _ accessToken: String) {
        
        SPTPlaylistList.playlists(
            forUser: username,
            withAccessToken: accessToken,
            
            callback: {
                
                (error, response) in
                
                if  let _firstPage = response as? SPTPlaylistList,
                    let _playlists = _firstPage.items as? [SPTPartialPlaylist] {
                    
                    self._playlists = _playlists
                    
                    if _firstPage.hasNextPage {
                        self._handlePlaylistGetNextPage(_firstPage, accessToken)
                    }
                }
            }
        )
    }
    
    func handleNewUserPlaylistSession() {
        
        _handlePlaylistGetFirstPage(
            appDelegate.spfUsername,
            appDelegate.spfCurrentSession!.accessToken!
        )
    }
    
    func handleNewPlayerSession() {
        
        if (_player?.loggedIn)! { return }
        
        do {
            
            try _player?.start(
                withClientId: appDelegate.spfAuth.clientID,
                audioController: nil,
                allowCaching: true
            )
            
            _player?.delegate = self
            _player?.playbackDelegate = self
            _player?.diskCache = SPTDiskCache()
            _player?.login(withAccessToken: appDelegate.spfCurrentSession!.accessToken!)
            
        } catch let error {
            
            let alert = UIAlertController(title: "Error Init Player", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: { _ in self.closeSpotifySession() })
        }
    }
    
    func closeSession() {
        
        do {
            
            try _player?.stop()
            
            closeSpotifySession()
            
            _ = self.navigationController!.popViewController(animated: true)
            
        } catch let error {
            
            let alert = UIAlertController(title: "Error Closing Player", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            
            self.present(alert, animated: true, completion: { _ in self.closeSpotifySession() })
        }
    }
    
    @IBAction func btnExitLandingPageAction(_ sender: Any) {
        
        //
        // if you close this view, your spotify session will be closed (not in use yet)
        //
        // closeSession()
        
        _ = self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func btnSpotifyCallAction(_ sender: Any) {
        
        for item in self._playlists {
            print ("name: \(item.name!), \(item.trackCount) songs")
            print ("uri: \(item.playableUri!)")
            print ("\n--\n")
        }
    }
}
