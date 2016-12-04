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
    
    var imageTemplate: UIImageView!
    
    override func didChangeStretchFactor(_ stretchFactor: CGFloat) {
        super.didChangeStretchFactor(stretchFactor)
        var alpha: CGFloat = 1
        if stretchFactor < 0.8 {
            alpha = CGFloatTranslateRange(stretchFactor / 0.9, 0.6, 0.9, 0, 1)
        }
        alpha = max(0, alpha)
        imageView.alpha = alpha
    }
    
    func configureImageViews() {
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 3, height: 3)
        imageView.layer.shadowOpacity = 0.8
        imageView.layer.shadowRadius = 10.0
        imageTemplate = UIImageView()
        imageTemplate.frame = imageView.bounds
        imageTemplate.contentMode = .scaleAspectFill
        imageTemplate.clipsToBounds = true
        imageView.addSubview(imageTemplate)
        backgroundImage.image = UIImage(named: "backgroundImage")
    }
}
