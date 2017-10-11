//
//  SPFPartialPlaylistExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 25.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import Foundation
import Spotify

extension SPTPartialPlaylist {

    func getMD5FingerPrint() -> String {
        
        return String(
            format: "%@:%D:%@:%@",
            self.name,
            self.trackCount,
            "\(self.isPublic)",
            "\(self.isCollaborative)").md5()
    }
}
