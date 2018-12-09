//
//  PlaylistEditViewFirstPage.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import WSTagsField

class PlaylistEditViewFirstPage: BasePlaylistEditViewController,
                                 UITextFieldDelegate {
    
    //
    // MARK: Class IBOutlet definitions
    //
    
    @IBOutlet weak var inpPlaylistName: UITextField!
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var imgPlaylistCoverBig: UIImageView!
    @IBOutlet weak var viewPlaylistTags: UIView!
    
    //
    // MARK: Class LowLevel Variables
    //
    
    var noCoverImageAvailable: Bool = true
    var noCoverOverrideImageAvailable: Bool = true
    var playlistUpdateDetected: Bool = false
    var imagePickerSuccess: Bool = false

    //
    // MARK: Constants (class)
    //
    
    let playlistTagsField = WSTagsField()
    let imagePickerController = UIImagePickerController()

    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUICoverImages()
        setupUIPlaylistTags()
        
        loadMetaPlaylistFromDb()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated); UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        
        subscribeToKeyboardNotifications()
        
        appDelegate.restrictRotation = .portrait
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        unSubscribeToKeyboardNotifications()
    }
    
    override func viewDidLayoutSubviews() {
        
        super.viewDidLayoutSubviews()
        
        playlistTagsField.frame = viewPlaylistTags.bounds
    }
    
    // set orientation to portrait(fix) in this editView
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        
        return UIInterfaceOrientationMask.portrait
    }
    
    // disable orientation switch in this editView
    override var shouldAutorotate: Bool {
        
        return false
    }
    
    //
    // MARK: Class Function Delegate Overloads
    //
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == playlistTagsField { return true }
        
        view.endEditing(true)
        
        return false
    }
    
    @objc
    func btnCoverOverrideTapped(sender: UITapGestureRecognizer) {
        
        if (sender.state != .ended) { return }
        
        var _title = "Pick an image"
        var _message = "Choose your image location"
        if   noCoverOverrideImageAvailable == false {
            _title = "Pick an image or reset the current one"
            _message = "Choose your image location or reset the current one to spotify default"
        }
        
        let alertController = UIAlertController(
            title: _title,
            message: _message,
            preferredStyle: .alert)
        
        if  noCoverOverrideImageAvailable == false {
            let photoResetAction = UIAlertAction(title: "Reset", style: UIAlertActionStyle.default) {
                UIAlertAction in
                
                self.playListInDb!.coverImagePathOverride = nil
                self.playListChanged = true
                self.handleBtnSavePlaylistChangesState( active: true )
                
                // refresh coverImage view after reset
                self.setupUICoverImages()
                
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
    
    func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
    }
    
    func isPhotoLibrarayAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
    }
    
    func isSavedPhotosAlbumAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.savedPhotosAlbum)
    }
    
    func isLocalImageStockAvailable() -> Bool {
        return isPhotoLibrarayAvailable() || isSavedPhotosAlbumAvailable()
    }
    
    func imagePickerController(
       _ picker: UIImagePickerController,
         didFinishPickingMediaWithInfo info: [String : Any]) {
        
        imagePickerSuccess = false
        imgPlaylistCoverBig.alpha = 1.0
        playListInDb!.coverImagePathOverride = nil
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            let _imageDataRaw = info[UIImagePickerControllerOriginalImage] as! UIImage
            let _imageDataResized = _imageDataRaw.kf.resize(to: _sysPlaylistCoverOverrideResize)
            let _imageDataCropped = _imageDataResized.kf.crop(
                to: _sysPlaylistCoverDetailImageSize,
                anchorOn: CGPoint(x: 10, y: 10)
            )
            
            playListInDb!.coverImagePathOverride = getSavedImageFileName(_imageDataCropped, String.random().md5())
            imgPlaylistCoverBig.image = pickedImage
            imgPlaylistCoverBig.alpha = _sysPlaylistCoverOriginInActiveAlpha
            imagePickerSuccess = true
        }
        
        // every change on successfull image pick will be result in a changed playlist
        playListChanged = imagePickerSuccess
        handleBtnSavePlaylistChangesState( active: imagePickerSuccess )
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(
       _ picker: UIImagePickerController) {
        
        imagePickerSuccess = false
        
        dismiss(animated: true, completion: nil)
    }
    
    func loadImagePickerSource() {
        
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
    
    //
    // MARK: Class IABaction Methods
    //
    
    @IBAction func inpPlaylistNameChanged(_ sender: Any) {
        
        handleBtnSavePlaylistChangesState( active: true )
    }

    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
        
        handlePlaylistMetaUpdate()
        dismiss(animated: true, completion: nil)
    }
}

