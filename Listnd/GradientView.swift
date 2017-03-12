//
//  GradientView.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 3/10/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//
import UIKit

class GradientView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        guard let theLayer = self.layer as? CAGradientLayer else {
            return;
        }
        
        theLayer.colors = [UIColor.darkGray.cgColor, UIColor.lightGray.cgColor]
        theLayer.locations = [0.0, 1.0]
        theLayer.frame = self.bounds
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
}

