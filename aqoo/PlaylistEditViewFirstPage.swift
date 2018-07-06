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
import WSTagsField

class PlaylistEditViewFirstPage: BasePlaylistEditViewController, UITextFieldDelegate {
    
    //
    // MARK: Class LowLevel Variables
    //
    
    var _noCoverImageAvailable: Bool = true
    var _noCoverOverrideImageAvailable: Bool = true
    
    fileprivate let tagsField = WSTagsField()
    
    @IBOutlet weak var imgPlaylistCoverBig: UIImageView!
    @IBOutlet weak var inpPlaylistName: UITextField!
    @IBOutlet fileprivate weak var viewPlaylistTags: UIView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUICoverImages()
        setupUIPlaylistName()
        setupUIPlaylistTags()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        tagsField.beginEditing()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tagsField.frame = viewPlaylistTags.bounds
    }
    
    //
    // MARK: Class Function Extensions
    //
    
    func setupUIPlaylistName() {
        
        inpPlaylistName.text = playListInDb!.metaListInternalName
    }
    
    func setupUIPlaylistTags() {
        
        viewPlaylistTags.frame = viewPlaylistTags.bounds
        viewPlaylistTags.addSubview(tagsField)
        
        tagsField.cornerRadius = 3.0
        tagsField.spaceBetweenLines = 10
        tagsField.spaceBetweenTags = 10
        tagsField.numberOfLines = 4
        
        tagsField.layoutMargins = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        tagsField.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        tagsField.backgroundColor = UIColor(netHex: 0x1ED761)
        tagsField.tintColor = UIColor(netHex: 0x1ED761)
        tagsField.textColor = .black
        tagsField.fieldTextColor = .white
        tagsField.selectedColor = .white
        tagsField.selectedTextColor = UIColor(netHex: 0x1ED761)
        
        tagsField.delimiter = ""
        tagsField.placeholder = "Enter a tag"
        tagsField.isDelimiterVisible = false
        tagsField.placeholderColor = .white
        tagsField.placeholderAlwaysVisible = true
        tagsField.backgroundColor = .clear
        
        tagsField.acceptTagOption = .space
        tagsField.returnKeyType = .next
        tagsField.textDelegate = self

        handlePlaylistTagEvents()
    }
    
    func handlePlaylistTagEvents() {
        
        tagsField.onDidAddTag = { _, _ in
            print("onDidAddTag")
        }
        
        tagsField.onDidRemoveTag = { _, _ in
            print("onDidRemoveTag")
        }
        
        tagsField.onDidChangeText = { _, text in
            print("onDidChangeText")
        }
        
        tagsField.onDidChangeHeightTo = { _, height in
            print("HeightTo \(height)")
        }
        
        tagsField.onDidSelectTagView = { _, tagView in
            print("Select \(tagView)")
        }
        
        tagsField.onDidUnselectTagView = { _, tagView in
            print("Unselect \(tagView)")
        }
        
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == tagsField {
            inpPlaylistName.becomeFirstResponder()
        }
        
        return true
    }
}

