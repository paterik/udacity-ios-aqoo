//
//  PlaylistEditViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension PlaylistEditViewController {
    
    func setupUIInputFields() {
        
        inpPlaylistTitle.text = playListInDb!.name
        inpPlaylistDescription.text = playListInDb!.metaListInternalDescription
        inpPlaylistDescription.delegate = self
    }
    
    func setupUI() {
        
        playListChanged = false
        inputsListenForChanges = [
            inpPlaylistTitle,
            inpPlaylistDescription
        ]
    }
    
    func setupUINavigation() {
        
        navItemEditViewTitle.title = playListInDb!.name
        handleSaveChangesButton(false)
    }
    
    func setupUISwitchButtons() { }
    
    func handleSaveChangesButton (_ enabled: Bool) {
        
        btnSavePlaylistChanges.isEnabled = enabled
    }
    
    func checkInputElementsForChanges() {
        
        for (_, element) in inputsListenForChanges.enumerated() {
            
            // check changes in playlist "title" element
            if let _element = element as? UITextField {
                playListChanged = false
                playListNameChanged = false
                if _element.text! != playListInDb!.name {
                    playListChanged = true
                    playListNameChanged = true
                };  handleSaveChangesButton(playListChanged)
                
                // previously change detected? leave this method now, no further change-detection necessary now
                if playListChanged { return }
            }
            
            // check changes in playlist "description" element
            if let _element = element as? UITextView {
                playListChanged = false
                playListDescriptionChanged = false
                if _element.text! != playListInDb!.metaListInternalDescription {
                    playListChanged = true
                    playListDescriptionChanged = true
                };  handleSaveChangesButton(playListChanged)
                
                // previously change detected? leave this method now, no further change-detection necessary now
                if playListChanged { return }
            }
        }
    }
}
