//
//  PlaylistEditViewTabBarController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
// import Spotify
import CoreStore
import Kingfisher

class PlaylistEditViewTabBarController: UITabBarController {
    //
    // MARK: Class Variables
    //
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
}
