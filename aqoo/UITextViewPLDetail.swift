//
//  UITextViewPLDetail.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 08.12.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

class UITextViewPLDetail : UITextView {
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 6, right: 8)
    }
}
