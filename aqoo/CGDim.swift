//
//  CGDim.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 29.12.17.
//  Copyright © 2017 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension CGRect {
    
    init(_ x: CGFloat,_ y: CGFloat,_ width: CGFloat,_ height: CGFloat) {
        self.init(x:x,y:y,width:width,height:height)
    }
    
}
extension CGSize {
    
    init(_ width: CGFloat,_ height: CGFloat) {
        self.init(width:width,height:height)
    }
}
extension CGPoint {
    
    init(_ x: CGFloat,_ y: CGFloat) {
        self.init(x:x,y:y)
    }
}
