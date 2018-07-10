//
//  PlaylistEditViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import FoldingCell
import BGTableViewRowActionWithImage
import fluid_slider

class PlaylistEditViewController: BaseViewController,
                                  UITextViewDelegate,
                                  UIImagePickerControllerDelegate,
                                  UINavigationControllerDelegate {

    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var navItemEditViewTitle: UINavigationItem!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var inpPlaylistTitle: UITextField!
    @IBOutlet var inpPlaylistRatingSlider: Slider!
    @IBOutlet var imgPlaylistCoverOrigin: UIImageView!
    @IBOutlet var btnPlaylistCoverOverride: UIButton!
    
    //
    // MARK: Constants (normal)
    //
    

    let imagePickerController = UIImagePickerController()
    
    //
    // MARK: Class Variables
    //
    
    var playListInDb: StreamPlayList?
    var playListInCloud: SPTPartialPlaylist?
    var playListChanged: Bool = false
    var playlistChangedItem: StreamPlayList?
    var imagePickerSuccess: Bool = false
    var inputsListenForChanges = [Any]()
    
    //
    // MARK: Class LowLevel Variables
    //
    
    var _noCoverImageAvailable: Bool = true
    var _noCoverOverrideImageAvailable: Bool = true
    
    enum tagFor: Int {
        case PlaylistTitle = 1
        case PlaylistVoting = 2
    }
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIGeneral()
        setupUINavigation()
        setupUIRatingSlider()
        setupUICoverImages()
    }
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupUIInputFields()
        
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showPlaylistEditViewDetail" {
            
            let editViewDetailController = segue.destination as! PlaylistEditViewDetailController
                // editViewDetailController.delegate = self
                editViewDetailController.playListInDb = playListInDb!
                editViewDetailController.playListInCloud = playListInCloud!
        }
    }

    //
    // MARK: Class Method Delegates
    //
    
    func textViewDidChange(_ sender: UITextView) {
        
        checkInputElementsForChanges()
    }
    
    //
    // MARK: Class IBAction Methods
    //
    
    @IBAction func inpPlaylistTitleDidChanged(_ sender: UITextField) {

        checkInputElementsForChanges()
    }
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {

        var _playListTitle: String = inpPlaylistTitle.text!
        var _playListRating: Float = Float(inpPlaylistRatingSlider.fraction)
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>()
                        .where(\.metaListHash == self.playListInDb!.metaListHash)
                )
                
                if  playlistToUpdate != nil {

                    playlistToUpdate!.metaListInternalName = _playListTitle
                    playlistToUpdate!.updatedAt = Date()
                    playlistToUpdate!.metaNumberOfUpdates += 1
                    playlistToUpdate!.metaPreviouslyUpdatedManually = true
                    playlistToUpdate!.metaListRatingOverall = _playListRating
                    playlistToUpdate!.isPlaylistHidden = self.playListInDb!.isPlaylistHidden
                    playlistToUpdate!.isPlaylistRadioSelected = self.playListInDb!.isPlaylistRadioSelected
                    playlistToUpdate!.isPlaylistVotedByStar = self.playListInDb!.isPlaylistVotedByStar
                    playlistToUpdate!.isPlaylistYourWeekly = self.playListInDb!.isPlaylistYourWeekly
                    playlistToUpdate!.coverImagePathOverride = self.playListInDb!.coverImagePathOverride
                    
                    //
                    // add some special order weight values for internal playlists
                    //
                    
                    if  playlistToUpdate!.isPlaylistRadioSelected == true {
                        playlistToUpdate!.metaWeight = filterInternalWeight.PlaylistRadioLiked.rawValue
                    }
                    
                    if  playlistToUpdate!.isPlaylistVotedByStar == true {
                        playlistToUpdate!.metaWeight = filterInternalWeight.PlaylistStarRated.rawValue
                    }
                    
                    if  playlistToUpdate!.isPlaylistYourWeekly == true {
                        playlistToUpdate!.metaWeight = filterInternalWeight.PlaylistYourWeekly.rawValue
                    }
                    
                    self.playListInDb = playlistToUpdate!
                }
            },
            completion: { (result) -> Void in
                
                switch result {
                case .failure(let error): if self.debugMode == true { print (error) }
                case .success(let userInfo):
                    self.handleSaveChangesButton( false )
                    self.btnExitEditViewAction( self )
                }
            }
        )
    }
    
    @IBAction func btnPlaylistCoverOverrideAction(_ sender: UIButton) {
        
        var _title = "Pick an image"
        var _message = "Choose your image location"
        if  _noCoverOverrideImageAvailable == false {
            _title = "Pick an image or reset the current one"
            _message = "Choose your image location or reset the current one to spotify default"
        }
        
        let alertController = UIAlertController(
            title: _title,
            message: _message,
            preferredStyle: .alert)
     
        if _noCoverOverrideImageAvailable == false {
            let photoResetAction = UIAlertAction(title: "Reset", style: UIAlertActionStyle.default) {
                UIAlertAction in
                
                self.playListInDb!.coverImagePathOverride = nil
                self.playListChanged = true
                self.handleSaveChangesButton( true )
                // reset cover override button now
                self.setupUICoverOverrideButton()
                
                return
            }
            
            alertController.addAction(photoResetAction)
        }
        
        if isPhotoLibrarayAvailable() {
            
            let photoLibAction = UIAlertAction(title: "From Photos", style: UIAlertActionStyle.default) {
                UIAlertAction in
                self.imagePickerController.sourceType = .photoLibrary
                self.loadImagePickerSource()
            }
            
            alertController.addAction(photoLibAction)
        }
        
        if isSavedPhotosAlbumAvailable() {
            
            let photoAlbumAction = UIAlertAction(title: "From Album", style: UIAlertActionStyle.default) {
                UIAlertAction in
                self.imagePickerController.sourceType = .savedPhotosAlbum
                self.loadImagePickerSource()
            }
            
            alertController.addAction(photoAlbumAction)
        }
        
        if isCameraAvailable() {
            
            let cameraAction = UIAlertAction(title: "From Camera", style: UIAlertActionStyle.default ) {
                UIAlertAction in
                self.imagePickerController.sourceType = .camera
                self.loadImagePickerSource()
            }
            
            alertController.addAction(cameraAction)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            UIAlertAction in return
        })
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func btnExitEditViewAction(_ sender: Any) {
        
        // delegate information about current playlist entity state to playlistView
        /*if let delegate = self.delegate {
            delegate.promoteToChanged( playListChanged )
            delegate.promoteChangedPlaylistObject( playListInDb! )
        }*/
        
        dismiss(animated: true, completion: nil)
    }
}
