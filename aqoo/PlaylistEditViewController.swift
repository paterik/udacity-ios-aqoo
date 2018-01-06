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
    
    var inputsListenForChanges = [Any]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        inputsListenForChanges = [inpPlaylistTitle, inpPlaylistDescription]
        
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
    
    }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    
}
