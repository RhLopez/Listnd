//
//  UIImageBlur.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/8/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func makeBlurImage(imageView: UIImageView?) {
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = imageView!.bounds
        
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView?.addSubview(blurEffectView)
    }
}
