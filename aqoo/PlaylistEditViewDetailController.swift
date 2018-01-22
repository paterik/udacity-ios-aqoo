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
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var inputsListenForChanges = [Any]()
    
    enum tagFor: Int {
        case PlaylistDescription = 1
        case PlaylistIsRadioSelected = 2
        case PlaylistIsVotingSelected = 3
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
    
    @IBAction func switchMyFavoriteListChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isHot)
    }
    
    @IBAction func switchAutoListLikedFromRadioChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistRadioSelected)
    }
    
    @IBAction func switchAutoListStarVotedChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistVotedByStar)
    }
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) { }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}
