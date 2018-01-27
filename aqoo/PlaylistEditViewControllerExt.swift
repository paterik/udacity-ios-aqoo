//
//  PlaylistEditViewControllerExt.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 05.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import fluid_slider

extension PlaylistEditViewController {
    
    func setupUIGeneral() {
        
        playListChanged = false
        inputsListenForChanges = [
            inpPlaylistTitle
        ]
        
        let labelTextAttributes: [NSAttributedStringKey : Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .bold), .foregroundColor: UIColor.white]
        
        slider.attributedTextForFraction = { fraction in
            
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
        
        slider.setMinimumLabelAttributedText(NSAttributedString(string: "0", attributes: labelTextAttributes))
        slider.setMaximumLabelAttributedText(NSAttributedString(string: "100", attributes: labelTextAttributes))
        slider.fraction = 0.5
        
        slider.shadowColor = UIColor(white: 0, alpha: 0.1)
        slider.contentViewColor = UIColor(netHex: 0x1DB954)
        slider.valueViewColor = .white
    }
    
    func setupUIInputFields() {
        
        inpPlaylistTitle.text = playListInDb!.metaListInternalName
    }
    
    func setupUINavigation() {
        
        navItemEditViewTitle.title = playListInDb!.metaListInternalName
        handleSaveChangesButton(false)
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
    
    func promoteChangedPlaylistObject(_ playlistItem: StreamPlayList ) {
        
        print ("dbg [delegate] : value transmitted -> PlaylistEditViewControllerExt :: playlistItem == [\(playlistItem.metaListInternalName)]")
    }
    
    func promoteToChanged(_ value: Bool) {
        
        print ("dbg [delegate] : value changed -> PlaylistEditViewControllerExt :: playlistChanged == \(value)")
        handleSaveChangesButton( value )
        playListChanged = value
    }
}
