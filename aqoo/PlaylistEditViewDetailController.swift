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
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var inputsListenForChanges = [Any]()
 
    enum tagFor: Int {
        case PlaylistDescription = 1
        case PlaylistIsStarVoted = 2
        case PlaylistIsRadioLiked = 3
        case PlaylistIsHidden = 4
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
    
    @IBAction func switchActionHidePlaylistFromAllViewsChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistHidden)
    }
    
    @IBAction func switchAutoListLikedFromRadioChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistRadioSelected)
    }
    
    @IBAction func switchAutoListStarVotedChanged(_ sender: UISwitch) {
        
        checkSwitchElementsForChanges(sender, playListInDb!.isPlaylistVotedByStar)
    }
    
    @IBAction func btnResetPlaylistStatistics(_ sender: UIButton) { }
    @IBAction func btnResetPlaylistToSPFDefaults(_ sender: UIButton) { }
    
    @IBAction func btnCancelEditViewAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}
