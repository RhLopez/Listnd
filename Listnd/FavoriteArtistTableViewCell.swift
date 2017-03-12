//
//  FavoriteArtistTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/15/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import SwipeCellKit

class FavoriteArtistTableViewCell: SwipeTableViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumCountLabel: UILabel!
    @IBOutlet weak var imageTemplate: UIImageView!
    
    
    var cell = FavoriteArtistTableViewCell.self {
        didSet {
            layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artistImageView.layer.cornerRadius = 4.0
        artistImageView.layer.masksToBounds = true
    }
    
}
