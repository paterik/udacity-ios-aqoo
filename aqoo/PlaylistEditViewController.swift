//
//  PlaylistEditViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//


import UIKit
import Spotify
import Kingfisher
import FoldingCell
import BGTableViewRowActionWithImage

class PlaylistEditViewController: BaseViewController {

    var playlistInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    
    @IBOutlet weak var navItemEditViewTitle: UINavigationItem!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        navItemEditViewTitle.title = playlistInDb!.name
        
        print ("LOAD_PLAYLIST -> [cache: \(playlistInDb!.name)]")
        print ("LOAD_PLAYLIST -> [cloud: \(playListInCloud!.name!)]")
    }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}
