//
//  PlaylistEditViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension PlaylistEditViewController {
    
    func setupUIGeneral() {
        
        playListChanged = false
        inputsListenForChanges = [
            inpPlaylistTitle,
            inpPlaylistDescription
        ]
    }
    
    func setupUIInputFields() {
        
        inpPlaylistTitle.text = playListInDb!.metaListInternalName
        inpPlaylistDescription.text = playListInDb!.metaListInternalDescription
        inpPlaylistDescription.delegate = self
    }
    
    func setupUINavigation() {
        
        navItemEditViewTitle.title = playListInDb!.metaListInternalName
        handleSaveChangesButton(false)
    }
    
    func setupUISwitchButtons() {
        
        switchMyFavoriteList.isOn = playListInDb!.isHot
        switchAutoListStarVoted.isOn = playListInDb!.isPlaylistVotedByStar
        switchAutoListLikedFromRadio.isOn = playListInDb!.isPlaylistRadioSelected
    }
    
    func checkSwitchElementsForChanges(_ switchElement: UISwitch, _ metaValue: Bool) {
        
        playListChanged = true
        if  switchElement.isOn == metaValue {
            playListChanged = false
        };  handleSaveChangesButton( playListChanged )
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
            
            // check changes in playlist "description" element
            if let _element = element as? UITextView {
                
                if _element.tag   != tagFor.PlaylistDescription.rawValue { return }
                if _element.text! != playListInDb!.metaListInternalDescription {
                    playListChanged = true
                };  handleSaveChangesButton(playListChanged)
                
                if playListChanged { return }
            }
        }
    }
    
    func handleSaveChangesButton (_ enabled: Bool) {
        
        btnSavePlaylistChanges.isEnabled = enabled
    }
}
