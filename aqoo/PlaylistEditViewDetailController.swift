//
//  PlaylistEditViewDetailController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 22.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import FoldingCell
import BGTableViewRowActionWithImage
import fluid_slider

class PlaylistEditViewDetailController: BaseViewController, UITextViewDelegate {
    
    @IBOutlet var switchPlaylistIsStarVoted: UISwitch!
    @IBOutlet var switchPlaylistIsRadioLiked: UISwitch!
    @IBOutlet var switchPlaylistIsHidden: UISwitch!
    @IBOutlet var inpPlaylistDescription: UITextView!
    @IBOutlet var navItemEditViewTitle: UINavigationItem!
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var inputsListenForChanges = [Any]()
    var delegate: PlaylistEditViewDetailDelegate?
 
    enum tagFor: Int {
        case PlaylistDescription = 1
        case PlaylistIsStarVoted = 2
        case PlaylistIsRadioLiked = 3
        case PlaylistIsHidden = 4
    }
    
    enum internalFlags: String {
        case PlaylistIsStarVoted = "isPlaylistVotedByStar"
        case PlaylistIsRadioLiked = "isPlaylistRadioSelected"
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIGeneral()
        setupUINavigation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupUIInputFields()
        setupUISwitchButtons()
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    // weazL :: bug_1002 - this won't be working ...
    func textViewDidChange(_ sender: UITextView) {
        
        checkInputElementsForChanges()
    }
    
    private func addNewFlagToPlaylist(_ playlistKeyProperty: String) {
        
        var _currentHash = playListInDb!.metaListHash
        var _currentName = playListInDb!.metaListInternalName
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> Void in
                
                let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>().where((\StreamPlayList.metaListHash == _currentHash))
                )
                
                if  playlistToUpdate != nil {
                    
                    if  playlistKeyProperty == internalFlags.PlaylistIsRadioLiked.rawValue {
                        playlistToUpdate!.isPlaylistRadioSelected = true
                        self.playListInDb!.isPlaylistRadioSelected = true
                    }
                    
                    if  playlistKeyProperty == internalFlags.PlaylistIsStarVoted.rawValue {
                        playlistToUpdate!.isPlaylistVotedByStar = true
                        self.playListInDb!.isPlaylistVotedByStar = true
                    }
                }
            },
            completion: { _ in
                
                if  self.debugMode == true {
                    print ("dbg [playlist] : current radio-playlist [\(_currentName)] handled -> CHANGED")
                }
            }
        )
    }
    
    private func removeOldFlagFromPlaylist(
       _ playListTarget: StreamPlayList,
       _ switchElement: UISwitch!,
       _ clause: ReferenceWritableKeyPath<StreamPlayList, Bool>
       ) {
        
        var _playlistTargetHash = playListTarget.metaListHash
        var _playlistTargetName = playListTarget.metaListInternalName
        
        //  ignore self-validation of current playlist and setOff switch actions
        if  playListTarget.metaListHash == playListInDb!.metaListHash || !switchElement.isOn {
            
            return
        }
        
        if  let _elementHint = switchElement.accessibilityHint {
            let  alertController = UIAlertController(
                 title: "Found Duplicate Usage of \(_elementHint)?",
                 message: "You've already a playlist flagged for \"\(_elementHint)\"! Do you want to remove this flag from Playlist \"\(_playlistTargetName)\" and use this flag for \"\(playListInDb!.metaListInternalName)\" instead?",
                
                 preferredStyle: .alert
            )
        
            alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) {
                
                UIAlertAction in
                
                CoreStore.perform(
                    
                    asynchronous: { (transaction) -> Void in
                        
                        let playlistToUpdate = transaction.fetchOne(
                            From<StreamPlayList>().where((\StreamPlayList.metaListHash == _playlistTargetHash))
                        )
                        
                        // deactivate isRadioVoted (old) flag from (old) playlist
                        if  playlistToUpdate != nil {
                            
                            if  clause.cs_keyPathString == internalFlags.PlaylistIsRadioLiked.rawValue {
                                playlistToUpdate!.isPlaylistRadioSelected = false
                                self.playListInDb!.isPlaylistRadioSelected = false
                            }
                            
                            if  clause.cs_keyPathString == internalFlags.PlaylistIsStarVoted.rawValue {
                                playlistToUpdate!.isPlaylistVotedByStar = false
                                self.playListInDb!.isPlaylistVotedByStar = false
                            }
                        }
                    },
                    completion: { _ in
                        
                        // update key property for current (edited) playlist
                        self.addNewFlagToPlaylist( clause.cs_keyPathString )
                    }
                )
                
                return
            })
            
            alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) {
                
                UIAlertAction in
                
                // reset current switch and return to caller
                switchElement.isOn = false; return
            })
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    private func validateDataForSingleBoolFlagPresence(
        _ clause: ReferenceWritableKeyPath<StreamPlayList, Bool>,
        _ switchElement: UISwitch!,
        _ value: Bool) {
        
        CoreStore.perform(
            
            asynchronous: { (transaction) -> StreamPlayList? in
                return transaction.fetchOne(From<StreamPlayList>().where(clause == value))
            },
            success: { (transactionPlaylist) in
                
                // a duplicate entry was found, handle this one first
                if  transactionPlaylist != nil {
                    self.removeOldFlagFromPlaylist (
                        transactionPlaylist!,
                        switchElement,
                        clause
                    )
                    
                } else {
                    
                    // no duplicate entry found, just update current playlist
                    self.addNewFlagToPlaylist( clause.cs_keyPathString )
                }
            },
            failure: { (error) in
                self._handleErrorAsDialogMessage(
                    "Error Validating Key-Value",
                    "Oops! An error occured while validating playlist property from local database ..."
                )
            }
        )
    }
    
    @IBAction func switchAutoListStarVotedChanged(_ sender: UISwitch) {

        // check db for any playlist currently flagged as starVoted
        validateDataForSingleBoolFlagPresence(\StreamPlayList.isPlaylistVotedByStar, switchPlaylistIsStarVoted, true)
        
        // only one if this internal spotify flags are allowed!
        if  switchPlaylistIsRadioLiked.isOn {
            switchPlaylistIsRadioLiked.isOn = !switchPlaylistIsStarVoted.isOn
        }
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistVotedByStar)
    }
    
    @IBAction func switchAutoListLikedFromRadioChanged(_ sender: UISwitch) {
        
        // check db for any playlist currently flagged as radioLiked
        validateDataForSingleBoolFlagPresence(\StreamPlayList.isPlaylistRadioSelected, switchPlaylistIsRadioLiked, true)
        
        // only one if this internal spotify flags are allowed!
        if  switchPlaylistIsStarVoted.isOn {
            switchPlaylistIsStarVoted.isOn = !switchPlaylistIsRadioLiked.isOn
        }
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistRadioSelected)
    }
    
    @IBAction func switchActionHidePlaylistFromAllViewsChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistHidden)
    }
    
    @IBAction func btnCancelEditViewAction(_ sender: Any) {
        
        // delegate information about current playlist entity state to playlistEditView
        if let delegate = self.delegate {
            
            playListInDb!.isPlaylistHidden = switchPlaylistIsHidden.isOn
            playListInDb!.isPlaylistRadioSelected = switchPlaylistIsRadioLiked.isOn
            playListInDb!.isPlaylistVotedByStar = switchPlaylistIsStarVoted.isOn
            playListInDb!.metaListInternalDescription = inpPlaylistDescription.text
            
            delegate.promoteToChanged( playListChanged )
            delegate.promoteChangedPlaylistObject( playListInDb! )
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnResetPlaylistStatistics(_ sender: UIButton) {
        
        print ("btnResetPlaylistStatistics:action")
    }
    
    @IBAction func btnResetPlaylistToSPFDefaults(_ sender: UIButton) {
        
        print ("btnResetPlaylistToSPFDefaults:action")
    }
}
