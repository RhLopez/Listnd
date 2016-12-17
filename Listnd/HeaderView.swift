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
            alpha = CGFloatTranslateRange(stretchFactor, 0.2, 1, 0, 1)
        }
        alpha = max(0, alpha)
        imageView.alpha = alpha
    }
    
    func configureImageViews() {
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 5)
        imageView.layer.shadowOpacity = 0.7
        imageView.layer.shadowRadius = 8.5
        let borderFrame = UIView()
        borderFrame.frame = imageView.bounds
        borderFrame.layer.cornerRadius = 4.0
        borderFrame.layer.masksToBounds = true
        imageView.addSubview(borderFrame)
        imageTemplate = UIImageView()
        imageTemplate.frame = imageView.bounds
        imageTemplate.contentMode = .scaleAspectFill
        imageTemplate.clipsToBounds = true
        borderFrame.addSubview(imageTemplate)
        backgroundImage.image = UIImage(named: "backgroundImage")
    }
}
