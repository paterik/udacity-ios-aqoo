//
//  UIView.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 09.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension UIView {
    
    public class func fromNib() -> Self {
        
        return fromNib(nibName: nil)
    }
    
    public class func fromNib(nibName: String?) -> Self {
        
        func fromNibHelper<T>(nibName: String?) -> T where T : UIView {
            let bundle = Bundle(for: T.self)
            let name = nibName ?? String(describing: T.self)
            return bundle.loadNibNamed(name, owner: nil, options: nil)?.first as? T ?? T()
        }
        
        return fromNibHelper(nibName: nibName)
    }
}

