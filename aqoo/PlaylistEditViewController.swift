//
//  PlaylistEditViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//


import UIKit
import Spotify
import CoreStore
import Kingfisher
import FoldingCell
import BGTableViewRowActionWithImage

class PlaylistEditViewController: BaseViewController, UITextViewDelegate {

    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var playListNameChanged: Bool = false
    var playListDescriptionChanged: Bool = false
    
    @IBOutlet weak var navItemEditViewTitle: UINavigationItem!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var inpPlaylistTitle: UITextField!
    @IBOutlet weak var inpPlaylistDescription: UITextView!
    
    var inputsListenForChanges = [Any]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUI()
        setupUINavigation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupUIInputFields()
        setupUISwitchButtons()
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }

    func textViewDidChange(_ textView: UITextView) {
    
        checkInputElementsForChanges()
    }
    
    @IBAction func inpPlaylistTitleDidChanged(_ sender: Any) {

        checkInputElementsForChanges()
    }
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {

        var _playListTitle: String = self.inpPlaylistTitle.text!
        var _playListDescription: String = self.inpPlaylistDescription.text!
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>()
                        .where(\.metaListHash == self.playListInDb!.metaListHash)
                )
                
                if  playlistToUpdate != nil {

                    playlistToUpdate!.updatedAt = Date()
                    playlistToUpdate!.metaPreviouslyUpdated = true
                    playlistToUpdate!.metaNumberOfUpdates += 1
                    
                    if  self.playListNameChanged == true {
                        print ("playlist name changed and persisted now!")
                        playlistToUpdate!.name = _playListTitle
                    }
                    
                    if  self.playListDescriptionChanged == true {
                        print ("playlist description changed and persisted now!")
                        playlistToUpdate!.metaListInternalDescription = _playListDescription
                    }
                }
            },
            completion: { _ in

                self.handleSaveChangesButton( false )
                self.btnExitEditViewAction( self )
            }
        )
    }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}
