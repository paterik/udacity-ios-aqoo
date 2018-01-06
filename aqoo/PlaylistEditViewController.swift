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

class PlaylistEditViewController: BaseViewController, UITextViewDelegate {

    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    
    @IBOutlet weak var navItemEditViewTitle: UINavigationItem!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    
    @IBOutlet weak var inpPlaylistTitle: UITextField!
    @IBOutlet weak var inpPlaylistDescription: UITextView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        inpPlaylistDescription.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        navItemEditViewTitle.title = playListInDb!.name
        inpPlaylistTitle.text = playListInDb!.name
        inpPlaylistDescription.text = playListInDb!.metaListInternalDescription
        playListChanged = false
        
        print ("LOAD_PLAYLIST -> [cache: \(playListInDb!.name)]")
        print ("LOAD_PLAYLIST -> [cloud: \(playListInCloud!.name!)]")
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
       
        print ("CHANGED_PLAYLIST -> detect description changes begin")
        if textView.text != playListInDb!.metaListInternalDescription {
            print ("REAL CHANGES DETECTED IN DESCRIPTION (0)")
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        print ("CHANGED_PLAYLIST -> detect description changes ended")
        
        if textView.text != playListInDb!.metaListInternalDescription {
            print ("REAL CHANGES DETECTED IN DESCRIPTION (1)")
        }
    }
    
    @IBAction func inpPlaylistTitleDidChanged(_ sender: Any) {
        
        print ("CHANGED_PLAYLIST -> detect title changed")
        
        if let _textField = sender as? UITextField {
            if _textField.text != playListInDb!.name {
                print ("REAL CHANGES DETECTED IN TITLE")
            }
        }
    }
    
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
    
    }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    
}
