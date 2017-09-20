//
//  LandingPageViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit

class LandingPageViewController: BaseViewController {
    
    @IBOutlet weak var btnSpotifyCall: UIButton!
    
    @IBOutlet weak var btnExitLandingPage: UIBarButtonItem!
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }

    @IBAction func btnExitLandingPageAction(_ sender: Any) {
    
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnSpotifyCallAction(_ sender: Any) {
        
    }
}
