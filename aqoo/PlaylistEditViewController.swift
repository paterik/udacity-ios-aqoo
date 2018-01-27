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
import fluid_slider

class PlaylistEditViewController: BaseViewController,
                                  UITextViewDelegate,
                                  PlaylistEditViewDetailDelegate {

    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var navItemEditViewTitle: UINavigationItem!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var inpPlaylistTitle: UITextField!
    @IBOutlet var slider: Slider!
    
    //
    // MARK: Class Variables
    //
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var inputsListenForChanges = [Any]()
    var delegate: PlaylistEditViewDetailDelegate?
    
    enum tagFor: Int {
        case PlaylistTitle = 1
        case PlaylistVoting = 2
    }
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIGeneral()
        setupUINavigation()
    }
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupUIInputFields()
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showPlaylistEditViewDetail" {
            
            let editViewDetailController = segue.destination as! PlaylistEditViewDetailController
                editViewDetailController.delegate = self
                editViewDetailController.playListInDb = playListInDb!
                editViewDetailController.playListInCloud = playListInCloud!
        }
    }

    //
    // MARK: Class Method Delegates
    //
    
    func textViewDidChange(_ sender: UITextView) {
        
        checkInputElementsForChanges()
    }
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func inpPlaylistTitleDidChanged(_ sender: UITextField) {

        checkInputElementsForChanges()
    }
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {

        var _playListTitle: String = inpPlaylistTitle.text!
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>()
                        .where(\.metaListHash == self.playListInDb!.metaListHash)
                )
                
                if  playlistToUpdate != nil {

                    playlistToUpdate!.metaListInternalName = _playListTitle
                    playlistToUpdate!.updatedAt = Date()
                    playlistToUpdate!.metaNumberOfUpdates += 1
                    playlistToUpdate!.metaPreviouslyUpdatedManually = true
                    self.playListInDb = playlistToUpdate!
                }
            },
            completion: { _ in

                self.handleSaveChangesButton( false )
                self.btnExitEditViewAction( self )
            }
        )
    }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        // delegate information about current playlist entity state to playlistView
        if let delegate = self.delegate {
            delegate.promoteToChanged( playListChanged )
            delegate.promoteChangedPlaylistObject( playListInDb! )
        }
        
        dismiss(animated: true, completion: nil)
    }
}
