//
//  PlaylistEditViewFirstPage.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher

class PlaylistEditViewFirstPage: BasePlaylistEditViewController {
    
    //
    // MARK: Class LowLevel Variables
    //
    
    var _noCoverImageAvailable: Bool = true
    var _noCoverOverrideImageAvailable: Bool = true
    
    @IBOutlet weak var imgPlaylistCoverBig: UIImageView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUICoverImages()
    }
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }

    func setupUICoverImages() {
        
        var _playListCoverURL: String?
        
        // evaluate the "perfect" cover for our detailView
        if (playListInDb!.largestImageURL != nil) {
            _playListCoverURL = playListInDb!.largestImageURL!
            _noCoverImageAvailable = false
        }   else if (playListInDb!.smallestImageURL != nil) {
            _playListCoverURL = playListInDb!.smallestImageURL!
            _noCoverImageAvailable = false
        }
        
        // cover image url available - using kf processing technics and render one
        if _noCoverImageAvailable == false {
            imgPlaylistCoverBig.kf.setImage(
                with: URL(string: _playListCoverURL!),
                placeholder: UIImage(named: _sysDefaultCoverImage),
                options: [
                    .transition(.fade(0.2)),
                    .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverDetailImageSize))
                ]
            )
        }
        
        if  playListInDb!.coverImagePathOverride != nil {
            _noCoverOverrideImageAvailable = false
            
            if let _image = getImageByFileName(playListInDb!.coverImagePathOverride!) {
                imgPlaylistCoverBig.alpha = _sysPlaylistCoverOriginInActiveAlpha
            }   else {
                _handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted image for your playlist")
            }
        }
    }
}
