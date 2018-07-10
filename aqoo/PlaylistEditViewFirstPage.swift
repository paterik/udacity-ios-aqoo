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

class PlaylistEditViewFirstPage: BasePlaylistEditViewController,
                                 UITextFieldDelegate {
    
    //
    // MARK: Class LowLevel Variables
    //
    
    var _noCoverImageAvailable: Bool = true
    var _noCoverOverrideImageAvailable: Bool = true
    var _playlistUpdateDetected: Bool = false
    
    fileprivate let playlistTagsField = WSTagsField()
    
    @IBOutlet weak var imgPlaylistCoverBig: UIImageView!
    @IBOutlet weak var inpPlaylistName: UITextField!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet fileprivate weak var viewPlaylistTags: UIView!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUI()
        setupUICoverImages()
        setupUIPlaylistTags()
        
        loadMetaPlaylistFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        playlistTagsField.beginEditing()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        playlistTagsField.frame = viewPlaylistTags.bounds
    }
    
    //
    // MARK: Class Function Delegate Overloads
    //
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == playlistTagsField {
            inpPlaylistName.becomeFirstResponder()
        }
        
        return true
    }
    
    //
    // MARK: Class Setup UI/UX Functions
    //
    
    func setupUI() {
        
        btnSavePlaylistChanges.isEnabled = false
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
            
            if  let _image = getImageByFileName(playListInDb!.coverImagePathOverride!) {
                imgPlaylistCoverBig.alpha = _sysPlaylistCoverOriginInActiveAlpha
            }   else {
               _handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted image for your playlist")
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
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistToUpdate = transaction.fetchOne(
                      From<StreamPlayList>().where(\.metaListHash == self.playListInDb!.metaListHash))
                      as? StreamPlayList else {
                          self._handleErrorAsDialogMessage(
                              "Cache Error", "unable to fetch playlist from local cache"
                          );   return
                }
                    
                playlistToUpdate.metaListInternalName = _playListTitle
                playlistToUpdate.updatedAt = Date()
                playlistToUpdate.metaNumberOfUpdates += 1
                playlistToUpdate.metaPreviouslyUpdatedManually = true
                
                self.playListInDb = playlistToUpdate
                
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    if  self.debugMode == true {
                        print ("dbg [db] : ERROR [\(error)]")
                    };  self._playlistUpdateDetected = false
                
                case .success(let userInfo):
                    if  self.debugMode == true {
                        print ("dbg [db] : Playlist [\(_playListTitle)] updated")
                    };  self._playlistUpdateDetected = true
                }
            }
        )
    }
    
    func handlePlaylistTagInput(_ tag: String, add: Bool) {
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let _playlistInContext = transaction.fetchOne(
                      From<StreamPlayList>().where(\.metaListHash == self.playListInDb!.metaListHash))
                      as? StreamPlayList else {
                        self._handleErrorAsDialogMessage(
                            "Cache Error", "unable to fetch playlist from local cache"
                        );   return
                }
                
                // try to evaluate current tag in right context
                var playlistTagToUpdate = transaction.fetchOne(
                    From<StreamPlayListTags>()
                        .where((\StreamPlayListTags.playlistTag == tag) &&
                               (\StreamPlayListTags.playlist == self.playListInDb!)
                    )
                )
                
                // add tag to StreamPlayListTags cache/db table
                if  playlistTagToUpdate == nil && add == true {
                    if self.debugMode == true { print ("TAG [\(tag)] ADDED") }
                    playlistTagToUpdate = transaction.create(Into<StreamPlayListTags>()) as StreamPlayListTags
                    playlistTagToUpdate!.playlistTag = tag
                    playlistTagToUpdate!.createdAt = Date()
                    playlistTagToUpdate!.updatedAt = Date()
                    playlistTagToUpdate!.playlist = _playlistInContext
                }
                
                // remove tag from StreamPlayListTags cache/db table
                if  playlistTagToUpdate != nil && add == false {
                    if self.debugMode == true { print ("TAG [\(tag)] REMOVED") }
                    transaction.delete(playlistTagToUpdate)
                    self.playlistTagsField.removeTag(tag)
                }
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    if  self.debugMode == true {
                        print ("dbg [db] : ERROR [\(error)]")
                    };  self._playlistUpdateDetected = false
                
                case .success(let userInfo):
                    if  self.debugMode == true {
                        print ("dbg [db] : TAG [\(tag)] loaded")
                    };  self._playlistUpdateDetected = true
                }
            }
        )
    }

    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
        
        handlePlaylistMetaUpdate()
        
        // delegate information about current playlist entity state to playlistView
        if  let delegate = self.delegate {
            delegate.onPlaylistChanged( playListInDb! )
        }
        
        dismiss(animated: true, completion: nil)
    }
}

