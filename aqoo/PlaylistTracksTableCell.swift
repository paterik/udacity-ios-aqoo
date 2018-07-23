//
//  PlaylistTracksTableCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 23.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

class PlaylistTracksTableCell: UITableViewCell {
    
    @IBOutlet weak var lblAlbumName: UILabel!
    @IBOutlet weak var lblTrackName: UILabel!
    @IBOutlet weak var lblTrackOverallPlaytime: UILabel!
    @IBOutlet weak var lblTrackCurrentPlaytime: UILabel!
    @IBOutlet weak var lblTrackPlayIndex: UILabel!
    
    @IBOutlet weak var imageViewAlbumCover: UIImageView!
    @IBOutlet weak var imageViewTrackIsExplicit: UIImageView!
    @IBOutlet weak var imageViewTrackIsPlayingIndicator: UIImageView!
    @IBOutlet weak var imageViewTrackIsPlayingSymbol: UIImageView!
}