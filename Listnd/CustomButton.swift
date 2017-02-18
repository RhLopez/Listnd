//
//  CustomButton.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 2/17/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = UIColor.white
            } else {
                self.backgroundColor = UIColor.orange
            }
        }
    }
}
