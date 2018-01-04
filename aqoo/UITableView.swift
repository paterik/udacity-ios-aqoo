//
//  UITableView.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 04.01.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//

import UIKit

extension UITableView {
    
    func refreshTable() {
        let indexPathForSection = NSIndexSet(index: 0)
        self.reloadSections(indexPathForSection as IndexSet, with: UITableViewRowAnimation.middle)
    }
}
