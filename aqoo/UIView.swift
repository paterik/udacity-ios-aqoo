//
//  UIView.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 09.02.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension UIView {
    
    var ancestors: AnyIterator<UIView> {
        var current: UIView = self
        
        return AnyIterator<UIView> {
            guard let parent = current.superview else {
                return nil
            }
            current = parent
            return parent
            
        }
    }

    class func getAllSubviews<T: UIView>(view: UIView) -> [T] {
        return view.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(view: subView) as [T]
            if let view = subView as? T {
                result.append(view)
            }
            return result
        }
    }
    
    func getAllSubviews<T: UIView>() -> [T] {
        return UIView.getAllSubviews(view: self) as [T]
    }
    
    
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

