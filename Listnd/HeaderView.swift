//
//  HeaderView.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 12/3/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import GSKStretchyHeaderView

class HeaderView: GSKStretchyHeaderView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    override func didChangeStretchFactor(_ stretchFactor: CGFloat) {
        super.didChangeStretchFactor(stretchFactor)
        var alpha: CGFloat = 1
        if stretchFactor < 0.8 {
            alpha = CGFloatTranslateRange(stretchFactor / 0.9, 0.6, 0.9, 0, 1)
        }
        alpha = max(0, alpha)
        imageView.alpha = alpha
        
        var imageSizeFactor: CGFloat = CGFloatTranslateRange(backgroundImage.frame.height, 64, backgroundImage.frame.height, 0, 1)
        imageSizeFactor = min(1, max(0, imageSizeFactor))
        var imageEdge: CGFloat = CGFloatInterpolate(imageSizeFactor, 64, 42)
        
    }
}
