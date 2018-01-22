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
        inpPlaylistDescription.text = playListInDb!.metaListInternalDescription
        inpPlaylistDescription.delegate = self
    }
    
    func setupUINavigation() {
        
        navItemEditViewTitle.title = playListInDb!.metaListInternalName
        handleSaveChangesButton(false)
    }
    
    func setupUISwitchButtons() {
        
        switchAutoListStarVoted.isOn = playListInDb!.isPlaylistVotedByStar
        switchAutoListLikedFromRadio.isOn = playListInDb!.isPlaylistRadioSelected
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
