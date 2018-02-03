//
//  PlaylistEditViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import fluid_slider
import Kingfisher
import CryptoSwift

extension PlaylistEditViewController {
    
    func setupUIRatingSlider() {
        
        let labelTextAttributes: [NSAttributedStringKey : Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        inpPlaylistRatingSlider.attributedTextForFraction = { fraction in
            
            let formatter = NumberFormatter()
            formatter.maximumIntegerDigits = 3
            formatter.maximumFractionDigits = 0
            
            let string = formatter.string(from: (fraction * 100) as NSNumber) ?? ""
            
            return NSAttributedString(string: string, attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: UIColor.black
                ]
            )
        }
        
        inpPlaylistRatingSlider.setMinimumLabelAttributedText(NSAttributedString(string: "0", attributes: labelTextAttributes))
        inpPlaylistRatingSlider.setMaximumLabelAttributedText(NSAttributedString(string: "100", attributes: labelTextAttributes))
        inpPlaylistRatingSlider.fraction = CGFloat(playListInDb!.metaListInternalRating)
        
        inpPlaylistRatingSlider.shadowColor = UIColor(white: 0, alpha: 0.1)
        inpPlaylistRatingSlider.contentViewColor = UIColor(netHex: 0x1DB954)
        inpPlaylistRatingSlider.valueViewColor = .white
        
        inpPlaylistRatingSlider.addTarget(self, action: #selector(checkInputPlaylistRatingChanged), for: .valueChanged)
    }
    
    func setupUIGeneral() {
        
        playListChanged = false
        imagePickerSuccess = false
        btnPlaylistCoverOverride.contentMode = .scaleAspectFit
        btnPlaylistCoverOverride.setBackgroundImage(UIImage(named: _sysDefaultCoverOverrideImage), for: UIControlState.normal)
        
        inputsListenForChanges = [
            inpPlaylistTitle
        ]
    }
    
    func setupUICoverImages() {
        
        var _playListCoverURL: String?
        var _noCoverImageAvailable: Bool = true
        
        // set delegate for imagePicker (cam, photoLib ...)
        imagePickerController.delegate = self
        
        // set default image before any kind of cover processing
        imgPlaylistCoverOrigin.image = UIImage(named: _sysDefaultCoverImage)
        
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
            imgPlaylistCoverOrigin.kf.setImage(
                with: URL(string: _playListCoverURL!),
                placeholder: UIImage(named: _sysDefaultCoverImage),
                options: [
                    .transition(.fade(0.2)),
                    .processor(ResizingImageProcessor(referenceSize: _sysPlaylistCoverDetailImageSize))
                ]
            )
        }
        
        if playListInDb!.coverImagePathOverride != nil {
            if let _image = getImageByFileName(playListInDb!.coverImagePathOverride!) {
                btnPlaylistCoverOverride.setBackgroundImage(_image, for: UIControlState.normal)
                btnPlaylistCoverOverride.setImage(UIImage(named: "icnSwitch_v1"), for: UIControlState.normal)
            }   else {
                _handleErrorAsDialogMessage("IO Error (Read)", "unable to load your own persisted image for your playlist")
            }
        }
    }
    
    func setupUIInputFields() {
        
        inpPlaylistTitle.text = playListInDb!.metaListInternalName
    }
    
    func setupUINavigation() {
        
        navItemEditViewTitle.title = playListInDb!.metaListInternalName
        handleSaveChangesButton(false)
    }
    
    func checkInputPlaylistRatingChanged() {
        
        playListChanged = false
        if inpPlaylistRatingSlider.fraction != CGFloat(playListInDb!.metaListInternalRating) {
            playListChanged = true
        };  handleSaveChangesButton(playListChanged)
    }
    
    func checkInputElementsForChanges() {
        
        for (_, element) in inputsListenForChanges.enumerated() {
            
            playListChanged = false
            
            // check changes in playlist "title" element
            if let _element = element as? UITextField {
                
                if _element.tag   != tagFor.PlaylistTitle.rawValue { return }
                if _element.text! != playListInDb!.metaListInternalName {
                    playListChanged = true
                };  handleSaveChangesButton(playListChanged)
                
                //
                // previously change detected? leave this method now,
                // no further change-detection necessary now
                //
                if playListChanged { return }
            }
        }
    }
    
    func handleSaveChangesButton (_ enabled: Bool) {
        
        btnSavePlaylistChanges.isEnabled = enabled
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
        imgPlaylistCoverOrigin.alpha = 1.0
        playListInDb!.coverImagePathOverride = nil
        
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {

            btnPlaylistCoverOverride.setBackgroundImage(pickedImage, for: UIControlState.normal)

            let _imageDataRaw = info[UIImagePickerControllerOriginalImage] as! UIImage
            let _imageDataResized = _imageDataRaw.kf.resize(to: _sysPlaylistCoverOverrideResize)
            let _imageDataCropped = _imageDataResized.kf.crop(
                to: _sysPlaylistCoverDetailImageSize,
                anchorOn: CGPoint(x: 10, y: 10)
            )
            
            playListInDb!.coverImagePathOverride = getSavedImageFileName(_imageDataCropped, String.random().md5())
            
            imgPlaylistCoverOrigin.alpha = 0.65
            imagePickerSuccess = true
        }
        
        // every change on successfull image pick will be result in a changed playlist
        playListChanged = imagePickerSuccess
        handleSaveChangesButton( imagePickerSuccess )
        
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
    
    func promoteChangedPlaylistObject(_ playlistItem: StreamPlayList ) {
        
        let _identifier = playlistItem.metaListInternalName
        print ("dbg [delegate] : value transmitted -> PlaylistEditViewControllerExt :: playlistItem == [\(_identifier)]")
    }
    
    func promoteToChanged(_ value: Bool) {
        
        print ("dbg [delegate] : value changed -> PlaylistEditViewControllerExt :: playlistChanged == \(value)")
        handleSaveChangesButton( value )
        playListChanged = value
    }
}
