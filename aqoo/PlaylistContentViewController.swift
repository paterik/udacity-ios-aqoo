//
//  PlaylistContentViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import BGTableViewRowActionWithImage

class PlaylistContentViewController: BaseViewController,
                                     UITableViewDataSource,
                                     UITableViewDelegate {
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListTracksInCloud: [StreamPlayListTracks]?
    
    @IBOutlet weak var tableView: UITableView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUITableView()
        
        loadMetaPlaylistTracksFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
    }
    
    //
    // MARK: Class Table Delegates
    //
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(
       _ tableView: UITableView,
         numberOfRowsInSection section: Int) -> Int {
        
        return playListTracksInCloud!.count
    }
    
    func tableView(
       _ tableView: UITableView,
         cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let playlistCell = tableView.dequeueReusableCell(
            withIdentifier: "playListContentItem",
            for: indexPath) as! UITableViewCell
        
        let playlistTrackCacheData = playListTracksInCloud![indexPath.row] as StreamPlayListTracks
        
        playlistCell.textLabel?.text = playlistTrackCacheData.trackName
        
        return playlistCell
    }
    
    @IBAction func btnClosePlayistContentView(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
}
