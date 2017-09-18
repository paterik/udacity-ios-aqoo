//
//  LoginViewController.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 18.09.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit

class LoginViewController: BaseViewController {

    @IBOutlet weak var imgLoginLock: UIImageView!
 
    @IBOutlet weak var btnSpotifyLogin: UIButton!
    @IBOutlet weak var btnSpotifyLogout: UIButton!
    @IBOutlet weak var lblSpotifySessionStatus: UILabel!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    @IBAction func btnSpotifyLoginAction(_ sender: Any) {
        
    }
    
    @IBAction func btnSpotifyLogoutAction(_ sender: Any) {
        
    }
}

