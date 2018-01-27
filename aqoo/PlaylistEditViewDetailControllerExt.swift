//
//  PlaylistEditViewDetailControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 22.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension PlaylistEditViewDetailController {

    func setupUIGeneral() {
        
        playListChanged = false
        inputsListenForChanges = [
            inpPlaylistDescription
        ]
    }
    
    func setupUIInputFields() {
        
        inpPlaylistDescription.text = playListInDb!.metaListInternalDescription
        inpPlaylistDescription.delegate = self
    }
    
    func setupUINavigation() {
        
        // navItemEditViewTitle.title = playListInDb!.metaListInternalName
    }
    
    func setupUISwitchButtons() {
        
        switchPlaylistIsStarVoted.isOn = playListInDb!.isPlaylistVotedByStar
        switchPlaylistIsRadioLiked.isOn = playListInDb!.isPlaylistRadioSelected
        switchPlaylistIsHidden.isOn = playListInDb!.isPlaylistHidden
    }
    
    func checkSwitchElementsForChanges(_ switchElement: UISwitch, _ metaValue: Bool) {
        
        playListChanged = true
        if  switchElement.isOn == metaValue {
            playListChanged = false
        }
    }
    
    func checkInputElementsForChanges() {
        
        for (_, element) in inputsListenForChanges.enumerated() {
            
            playListChanged = false
            
            // check changes in playlist "description" element
            if let _element = element as? UITextView {
                
                if _element.tag   != tagFor.PlaylistDescription.rawValue { return }
                if _element.text! != playListInDb!.metaListInternalDescription {
                    playListChanged = true
                }
                
                if playListChanged { return }
            }
        }
    }
}
