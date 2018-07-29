//
//  PlaylistTracksControlView.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 23.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

class PlaylistTracksControlView: UIView {
    
    @IBOutlet weak var lblPlaylistName: UILabel!
    @IBOutlet weak var lblPlaylistOverallPlaytime: UILabel!
    @IBOutlet weak var lblPlaylistTrackCount: UILabel!
    
    @IBOutlet weak var btnPlayRepeatMode: UIButton!
    @IBOutlet weak var btnPlayShuffleMode: UIButton!
    @IBOutlet weak var btnPlayNormalMode: UIButton!
    
    @IBOutlet weak var imageViewPlaylistIsPlayingIndicator: PlaylistMusicIndicatorView!
    @IBOutlet weak var imageViewPlaylistCover: UIImageView!  
}
