//
//  UITableViewCell+extensions.swift
//  JSONTest
//
//  Created by Tom Harrington on 7/15/16.
//  Copyright © 2016 Atomic Bird LLC. All rights reserved.
//

import UIKit

extension UITableViewCell {
    static var defaultReuseIdentifier : String {
        get {
            return String(describing: self)
        }
    }
}
