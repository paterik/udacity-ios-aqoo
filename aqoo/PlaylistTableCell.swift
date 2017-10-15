//
//  PlaylistTableCell.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 15.10.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit
import FoldingCell

class PlaylistTableCell: UITableViewCell {
    
    @IBOutlet weak var lblPlaylistName: UILabel!
    @IBOutlet weak var lblPlaylistFullPlaytime: UILabel!
    @IBOutlet weak var lblPlaylistTrackCount: UILabelDesignable!
    
    @IBOutlet weak var imageViewPlaylistCover: UIImageView!
    @IBOutlet weak var imageViewPlaylistTrackCount: UIImageView!
}
