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
    @IBOutlet weak var navigationLabel: UILabel!
    
    var imageTemplate: UIImageView!
    var gradientView: UIView!
    
    override func didChangeStretchFactor(_ stretchFactor: CGFloat) {
        super.didChangeStretchFactor(stretchFactor)
        var alpha: CGFloat = 1
        var gradientAlpha: CGFloat = 1
        
        if stretchFactor > 1 {
            gradientAlpha = CGFloatTranslateRange(stretchFactor, 1, 1.03, 1, 0)
        } else if stretchFactor < 0.8 {
            alpha = CGFloatTranslateRange(stretchFactor, 0.2, 1, 0, 1)
        }
        
        let navTitleFactor: CGFloat = 0.4
        var navTitleAlpha: CGFloat = 0
        if stretchFactor < navTitleFactor {
            navTitleAlpha = CGFloatTranslateRange(stretchFactor, 0, navTitleFactor, 1, 0)
        }
        
        alpha = max(0, alpha)
        backgroundImage.alpha = alpha
        nameLabel.alpha = alpha
        gradientView.alpha = gradientAlpha
        navigationLabel.alpha = navTitleAlpha
    }
    
    func configureView(name: String, imageData: Data?, hideButton: Bool) {
        addButton.layer.cornerRadius = 3.0
        addButton.setTitleColor(UIColor.white, for: .normal)
        addButton.setTitleColor(UIColor.black, for: .highlighted)
        
        nameLabel.numberOfLines = 0
        nameLabel.lineBreakMode = .byWordWrapping
        nameLabel.sizeToFit()
        nameLabel.layer.cornerRadius = 4.0
        nameLabel.layer.masksToBounds = true
        nameLabel.text = name
        navigationLabel.text = name
        if let data = imageData {
            backgroundImage.image = UIImage(data: data)
        } else {
            backgroundImage.image = UIImage(named: "headerPlaceHolder")
        }
        
        addButton.isHidden = hideButton
        addGradient()
    }
    
    func setImage(data: Data) {
        let image = UIImage(data: data)
        UIView.transition(with: self.backgroundImage, duration: 1, options: .transitionCrossDissolve, animations: { self.backgroundImage.image = image }, completion: nil)
    }
    
    func addGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: contentView.frame.height)
        gradient.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        gradient.opacity = 0.30
        gradient.locations = [0.0, 1.0]
        gradientView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: contentView.frame.height))
        gradientView.layer.addSublayer(gradient)
        backgroundImage.addSubview(gradientView)
    }
}
