//
//  PlaylistEditViewSecondPage.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 13.06.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit
import Spotify
import CoreStore
import Kingfisher
import fluid_slider

class PlaylistEditViewSecondPage: BasePlaylistEditViewController {
    
    var playlistUpdateDetected: Bool = false
    
    @IBOutlet weak var btnSavePlaylistChanges: UIBarButtonItem!
    @IBOutlet weak var cViewPlaylistRatingIntensity: Slider!
    @IBOutlet weak var cViewPlaylistRatingEmotional: Slider!
    @IBOutlet weak var cViewPlaylistRatingDepth: Slider!
    @IBOutlet weak var lblPlaylistRatingAverageValue: UILabel!
    
    //
    // MARK: Class Method Overloads
    //
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setupUIBase()
        setupUIPlaylistRatingSliders()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
    
    //
    // MARK: Class Setup UI/UX Functions
    //
    
    func setupUIBase() {
        
        btnSavePlaylistChanges.isEnabled = false
    }
    
    func setupUIPlaylistRatingSliders() {
        
        setupUIPlaylistRatingSlider(cViewPlaylistRatingIntensity, playListInDb!.metaListRatingArousal / 100)
        setupUIPlaylistRatingSlider(cViewPlaylistRatingEmotional, playListInDb!.metaListRatingValence / 100)
        setupUIPlaylistRatingSlider(cViewPlaylistRatingDepth, playListInDb!.metaListRatingDepth / 100)
    }
    
    func setupUIPlaylistRatingSlider(_ sliderView: Slider, _ sliderInitValue: Float) {
        
        let labelTextAttributes: [NSAttributedStringKey : Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        sliderView.attributedTextForFraction = { fraction in
            
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
        sliderView.setMinimumLabelAttributedText(NSAttributedString(string: "0", attributes: labelTextAttributes))
        sliderView.setMaximumLabelAttributedText(NSAttributedString(string: "100", attributes: labelTextAttributes))
        sliderView.fraction = CGFloat(sliderInitValue)
        
        sliderView.shadowColor = UIColor(white: 0, alpha: 0.1)
        sliderView.contentViewColor = UIColor(netHex: 0x1DB954)
        sliderView.valueViewColor = .white
        
        sliderView.addTarget(self, action: #selector(handleInputPlaylistRatingChanged), for: .valueChanged)
    }
    
    func getOverallRatingFromThreeWayFaction() -> Float {
     
        return Float(((
            cViewPlaylistRatingIntensity.fraction +
            cViewPlaylistRatingEmotional.fraction +
            cViewPlaylistRatingDepth.fraction
            ) / 3)) * 100
    }
    
    func handlePlaylistMetaUpdate() {
        
        var _playListRatingArousal: Float = Float(cViewPlaylistRatingIntensity.fraction) * 100
        var _playListRatingValence: Float = Float(cViewPlaylistRatingEmotional.fraction) * 100
        var _playListRatingDepth:   Float = Float(cViewPlaylistRatingDepth.fraction) * 100
        var _overall:               Float = self.getOverallRatingFromThreeWayFaction()
        
        CoreStore.perform(
            asynchronous: { (transaction) -> Void in
                
                // find persisted playlist object from local cache (db)
                guard let playlistToUpdate = transaction.fetchOne(
                    From<StreamPlayList>().where(\.metaListHash == self.playListInDb!.metaListHash))
                    as? StreamPlayList else {
                        self.handleErrorAsDialogMessage(
                            "Cache Error", "unable to fetch playlist from local cache"
                        );   return
                }
                
                playlistToUpdate.updatedAt = Date()
                playlistToUpdate.metaNumberOfUpdates += 1
                playlistToUpdate.metaPreviouslyUpdatedManually = true
                playlistToUpdate.metaListRatingArousal = _playListRatingArousal
                playlistToUpdate.metaListRatingValence = _playListRatingValence
                playlistToUpdate.metaListRatingDepth = _playListRatingDepth
                playlistToUpdate.metaListRatingOverall = self.getOverallRatingFromThreeWayFaction()
                
                self.playListInDb = playlistToUpdate
            },
            completion: { (result) -> Void in
                switch result {
                    
                case .failure(let error):
                    
                    self.handleBtnSavePlaylistChangesState( active: false )
                    self.handleErrorAsDialogMessage(
                        "Cache Error", "unable to update playlist local cache"
                    )
                    
                case .success(let userInfo):
                    
                    // delegate information about current playlist state to parentView
                    self.handleBtnSavePlaylistChangesState( active: true )
                    if  let delegate = self.delegate {
                        delegate.onPlaylistChanged( self.playListInDb! )
                    }
                }
            }
        )
    }
    
    func handleBtnSavePlaylistChangesState(active: Bool) {
        
        btnSavePlaylistChanges.isEnabled = active
    }
    
    @objc
    func handleInputPlaylistRatingChanged() {
        
        playlistUpdateDetected = false
        if  (cViewPlaylistRatingIntensity.fraction != CGFloat(playListInDb!.metaListRatingArousal)) ||
            (cViewPlaylistRatingEmotional.fraction != CGFloat(playListInDb!.metaListRatingValence)) ||
            (cViewPlaylistRatingDepth.fraction     != CGFloat(playListInDb!.metaListRatingDepth)) {
            
            playlistUpdateDetected = true
        }
    
        let playlistRatingAverageValue = (getOverallRatingFromThreeWayFaction() * 100).rounded() / 100
        lblPlaylistRatingAverageValue.text = "\(playlistRatingAverageValue)"
        
        handleBtnSavePlaylistChangesState( active: playlistUpdateDetected )
    }
    
    //
    // MARK: Class IABaction Methods
    //
    
    @IBAction func btnSavePlaylistChangesAction(_ sender: Any) {
        
        handlePlaylistMetaUpdate()
        dismiss(animated: true, completion: nil)
    }
}
