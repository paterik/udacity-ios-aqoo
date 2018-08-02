//
//  PlaylistTracksControlView.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 23.07.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

class PlaylistTracksControlView: UIView {
    
    @IBOutlet weak var lblPlaylistName: UILabel!
    @IBOutlet weak var lblPlaylistOverallPlaytime: UILabel!
    @IBOutlet weak var lblPlaylistTrackCount: UILabel!
    
    @IBOutlet weak var btnPlayRepeatMode: UIButton!
    @IBOutlet weak var btnPlayShuffleMode: UIButton!
    @IBOutlet weak var btnPlayNormalMode: UIButton!
    
    @IBOutlet weak var imageViewPlaylistIsPlayingIndicator: PlaylistMusicIndicatorView!
    @IBOutlet weak var imageViewPlaylistCover: UIImageView!
    
    var mode: PlaylistMusicPlayMode = .playNormal {
        
        didSet {
            
            switch mode {
                
                case .playNormal:
                    
                    btnPlayNormalMode.backgroundColor = UIColor(netHex: 0x1ED761)
                    btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_1"), for: UIControlState.normal)
                    btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_0"), for: [UIControlState.selected, UIControlState.highlighted])
                    
                    break
                
                case .playShuffle:
                    
                    btnPlayShuffleMode.backgroundColor = UIColor(netHex: 0x1ED761)
                    btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_1"), for: UIControlState.normal)
                    btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_0"), for: [UIControlState.selected, UIControlState.highlighted])
                    
                    break
                
                case .playLoop:
                    
                    btnPlayRepeatMode.backgroundColor = UIColor(netHex: 0x1ED761)
                    btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_1"), for: UIControlState.normal)
                    btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_0"), for: [UIControlState.selected, UIControlState.highlighted])
                    
                    break
                
                case .clear:
                    
                    resetPlayNormalButton()
                    resetPlayLoopButton()
                    resetPlayShuffleButton()
                    
                    break
                
                default: return
            }
        }
    }
    
    func resetPlayNormalButton() {
        
        btnPlayNormalMode.backgroundColor = UIColor.clear
        btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_0"), for: UIControlState.normal)
        btnPlayNormalMode.setImage(UIImage(named : "icnSetPlayNormal_1"), for: [UIControlState.selected, UIControlState.highlighted])
    }
    
    func resetPlayLoopButton() {
        
        btnPlayRepeatMode.backgroundColor = UIColor.clear
        btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_0"), for: UIControlState.normal)
        btnPlayRepeatMode.setImage(UIImage(named : "icnSetPlayRepeatAll_1"), for: [UIControlState.selected, UIControlState.highlighted])
    }
    
    func resetPlayShuffleButton() {
        
        btnPlayShuffleMode.backgroundColor = UIColor.clear
        btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_0"), for: UIControlState.normal)
        btnPlayShuffleMode.setImage(UIImage(named : "icnSetPlayShuffle_1"), for: [UIControlState.selected, UIControlState.highlighted])
    }
    
    var state: PlaylistMusicIndicatorViewState = .stopped {
        
        didSet {
            imageViewPlaylistIsPlayingIndicator.state = state
        }
    }
}
