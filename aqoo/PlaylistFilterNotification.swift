//
//  PlaylistFilterNotification.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 09.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

class PlaylistFilterNotification: UIView {
    
    @IBOutlet var lblTitle: UILabel!
    @IBOutlet var lblSubTitle: UILabel!
    @IBOutlet var imgViewNotificationDefault: UIImageView!
    
    var notificationTitle: String?
    var notificationSubTitle: String?
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        initNotificationBox()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        initNotificationBox()
    }

    func initNotificationBox() {
        
        if notificationTitle != nil {
            lblTitle.text = notificationTitle
        }
        
        if notificationSubTitle != nil {
            lblSubTitle.text = notificationSubTitle
        }
    }
}


