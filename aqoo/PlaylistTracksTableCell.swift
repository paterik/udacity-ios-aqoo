//
//  PlaylistTracksTableCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 23.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialProgressView

class PlaylistTracksTableCell: UITableViewCell {
    
    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var lblAlbumName: UILabel!
    @IBOutlet weak var lblTrackName: UILabel!
    @IBOutlet weak var lblTrackPlaytime: UILabel!
    @IBOutlet weak var lblTrackPlaytimeRemaining: UILabel!
    @IBOutlet weak var lblTrackPlayIndex: UILabel!
    
    @IBOutlet weak var progressBar: MDCProgressView!
    @IBOutlet weak var imageViewAlbumCover: UIImageView!
    @IBOutlet weak var imageViewTrackIsExplicit: UIImageView!
    @IBOutlet weak var imageViewTrackIsPlayingIndicator: PlaylistMusicIndicatorView!
    @IBOutlet weak var imageViewTrackIsPlayingSymbol: UIImageView!
    
    //
    // MARK: Class Properties
    //
    
    var state: PlaylistMusicIndicatorViewState = .stopped {
        didSet { imageViewTrackIsPlayingIndicator.state = state }
    }
}
