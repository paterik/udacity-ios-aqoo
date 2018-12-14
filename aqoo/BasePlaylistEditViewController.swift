//
//  BasePlaylistEditViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import CoreStore
import Kingfisher

class BasePlaylistEditViewController: BaseViewController,
      UITextViewDelegate,
      UIImagePickerControllerDelegate,
      UINavigationControllerDelegate {
    
    //
    // MARK: Class Variables
    //
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var playlistChangedItem: StreamPlayList?
    var delegate: PlaylistViewUpdateDelegate?
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func btnExitEditViewPage(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
}
