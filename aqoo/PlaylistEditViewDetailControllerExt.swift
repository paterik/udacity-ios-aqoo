//
//  PlaylistEditViewDetailControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 22.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension PlaylistEditViewDetailController {

    func setupUIGeneral() {}
    func setupUIInputFields() {}
    func setupUINavigation() {}
    func setupUISwitchButtons() {}
    
    func checkSwitchElementsForChanges(_ switchElement: UISwitch, _ metaValue: Bool) {
        
        playListChanged = true
        if  switchElement.isOn == metaValue {
            playListChanged = false
        };  handleSaveChangesButton( playListChanged )
    }
    
    func checkInputElementsForChanges() {
        
        for (_, element) in inputsListenForChanges.enumerated() {
            
            playListChanged = false
            
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
}
