//
//  PlaylistEditViewFirstPageExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 17.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Kingfisher
import CryptoSwift
import CoreStore

extension PlaylistEditViewFirstPage {
 
    //
    // MARK: Class Setup UI/UX Functions
    //
    
    func setupUIBase() {
        
        btnSavePlaylistChanges.isEnabled = false
        inpPlaylistName.delegate = self
        imagePickerController.delegate = self
        imagePickerSuccess = false
    }
    
    func setupUIPlaylistTags() {
        
        viewPlaylistTags.frame = viewPlaylistTags.bounds
        viewPlaylistTags.addSubview(playlistTagsField)
        
        playlistTagsField.cornerRadius = 3.0
        playlistTagsField.spaceBetweenLines = 10
        playlistTagsField.spaceBetweenTags = 10
        playlistTagsField.numberOfLines = 4
        
        playlistTagsField.layoutMargins = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        playlistTagsField.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        
        playlistTagsField.backgroundColor = UIColor(netHex: 0x1ED761)
        playlistTagsField.tintColor = UIColor(netHex: 0x1ED761)
        playlistTagsField.textColor = .black
        playlistTagsField.fieldTextColor = .white
        playlistTagsField.selectedColor = .white
        playlistTagsField.selectedTextColor = .black
        
        playlistTagsField.placeholder = "Enter a tag"
        playlistTagsField.isDelimiterVisible = false
        playlistTagsField.placeholderColor = .white
        playlistTagsField.placeholderAlwaysVisible = true
        playlistTagsField.backgroundColor = .clear
        
        playlistTagsField.acceptTagOption = .space
        playlistTagsField.returnKeyType = .next
        playlistTagsField.textDelegate = self
        
        handlePlaylistTagEvents()
    }
    
    func setupUICoverImages() {
        
        var _playListCoverURL: String?
        
        imgPlaylistCoverBig.isUserInteractionEnabled = true
        imgPlaylistCoverBig.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(PlaylistEditViewFirstPage.btnCoverOverrideTapped))
        )
        
        // checkcover override status and load origin cover structure only if no user-generated cover was found
        if  playListInDb!.coverImagePathOverride != nil {
            noCoverOverrideImageAvailable = false
            
            if  let _image = getImageByFileName(playListInDb!.coverImagePathOverride!) {
                imgPlaylistCoverBig.alpha = _sysPlaylistCoverOriginInActiveAlpha
                imgPlaylistCoverBig.image = _image
            }   else {
                handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted image for your playlist")
            }
            
        }   else {
            
            // evaluate the "perfect" cover for our detailView
            if (playListInDb!.largestImageURL != nil) {
                _playListCoverURL = playListInDb!.largestImageURL!
                noCoverImageAvailable = false
            }   else if (playListInDb!.smallestImageURL != nil) {
                _playListCoverURL = playListInDb!.smallestImageURL!
                noCoverImageAvailable = false
            }
            
            // cover image url available - using kf processing technics and render one
            if  noCoverImageAvailable == false {
                imgPlaylistCoverBig.kf.setImage(
                    with: URL(string: _playListCoverURL!),
                    placeholder: UIImage(named: _sysDefaultCoverImage),
                    options: [
                        .transition(.fade(0.2)),
                        .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverDetailImageSize))
                    ]
                )
            }
        }
    }
    
    //
    // MARK: Class Setup Data/Meta Functions
    //
    
    func loadMetaPlaylistFromDb() {
        
        // load playlistName
        inpPlaylistName.text = playListInDb!.metaListInternalName
        
        // fetch all available tags for this playlist and load them to our tagView
        if  let _playListTagsInCache = CoreStore.defaultStack.fetchAll(
            From<StreamPlayListTags>().where(
                (\StreamPlayListTags.playlist == playListInDb!))
            ) {
            
            for _tag in _playListTagsInCache {
                self.playlistTagsField.addTag(_tag.playlistTag)
            }
        }
    }
    
    func handlePlaylistTagEvents() {
        
        playlistTagsField.onDidAddTag = { _, tag in
            self.btnSavePlaylistChanges.isEnabled = true
            self.handlePlaylistTagInput( tag.text.lowercased(), add: true )
        }
        
        playlistTagsField.onDidRemoveTag = { _, tag in
            self.btnSavePlaylistChanges.isEnabled = true
            self.handlePlaylistTagInput( tag.text.lowercased(), add: false )
        }
    }
    
    func handlePlaylistMetaUpdate() {
        
        var _playListTitle: String = inpPlaylistName.text!
        
        CoreStore.defaultStack.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>().where(\.metaListHash == self.playListInDb!.metaListHash))
                    as? StreamPlayList else {
                        self.handleErrorAsDialogMessage(
                            "Cache Error", "unable to fetch playlist from local cache"
                        );   return
                }
                
                playlistToUpdate.metaListInternalName = _playListTitle
                playlistToUpdate.metaNumberOfUpdates += 1
                playlistToUpdate.metaPreviouslyUpdatedManually = true
                playlistToUpdate.coverImagePathOverride = self.playListInDb!.coverImagePathOverride
                playlistToUpdate.updatedAt = Date()
                
                self.playListInDb = playlistToUpdate
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    
                    self.handleBtnSavePlaylistChangesState( active: false )
                    self.handleErrorAsDialogMessage(
                        "Cache Error", "unable to update playlist local cache"
                    )
                    
                case .success(let userInfo):
                    
                    // delegate information about current playlist state to parentView
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if  let delegate = self.delegate {
                        delegate.onPlaylistChanged( self.playListInDb! )
                    }
                }
            }
        )
    }
    
    func handlePlaylistTagInput(_ tag: String, add: Bool) {
        
        CoreStore.defaultStack.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistInContext = transaction.fetchOne(
                    From<StreamPlayList>().where(
                        \.metaListHash == self.playListInDb!.metaListHash
                )) as? StreamPlayList else {
                    self.handleErrorAsDialogMessage("Cache Error", "unable to fetch playlist from local cache")
                    
                    return
                }
                
                // try to evaluate current tag in right playlist context
                var playlistTagToUpdate = transaction.fetchOne(
                    From<StreamPlayListTags>()
                        .where((\StreamPlayListTags.playlistTag == tag) &&
                            (\StreamPlayListTags.playlist == self.playListInDb!)
                    )
                )
                
                //  add tag to StreamPlayListTags cache/db table
                if  add == true {
                    playlistTagToUpdate = transaction.create(Into<StreamPlayListTags>()) as StreamPlayListTags
                    playlistTagToUpdate!.playlistTag = tag
                    playlistTagToUpdate!.createdAt = Date()
                    playlistTagToUpdate!.updatedAt = Date()
                    playlistTagToUpdate!.playlist = playlistInContext
                    
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if self.debugMode == true { print ("TAG [\(tag)] ADDED") }
                }
                
                //  remove tag from StreamPlayListTags cache/db table
                if  add == false {
                    transaction.delete(playlistTagToUpdate)
                    
                    self.playlistTagsField.removeTag(tag)
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if self.debugMode == true { print ("TAG [\(tag)] REMOVED") }
                }
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    self.handleBtnSavePlaylistChangesState( active: false )
                    self.handleErrorAsDialogMessage(
                        "Cache Error", "unable to update playlist tag local cache"
                    )
                    
                case .success(let userInfo):
                    if  self.debugMode == true {
                        print ("dbg [db] : TAG [\(tag)] loaded")
                    }
                }
            }
        )
    }
    
    func handleBtnSavePlaylistChangesState(active: Bool) {
        
        btnSavePlaylistChanges.isEnabled = active
        playlistUpdateDetected = active
    }
    
    func subscribeToKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PlaylistEditViewFirstPage.keyboardWillAppear),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PlaylistEditViewFirstPage.keyboardWillDisappear),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
    }
    
    func unSubscribeToKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.UIKeyboardWillShow, object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self, name: NSNotification.Name.UIKeyboardWillHide, object: nil
        )
    }
    
    @objc
    func keyboardWillDisappear(notification: NSNotification) {
        
        view.frame.origin.y = 0
    }
    
    @objc
    func keyboardWillAppear(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height {
            view.frame.origin.y =  keyboardSize * -1
        }
    }
}
