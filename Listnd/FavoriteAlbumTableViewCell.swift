//
//  FavoriteAlbumTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/16/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import SwipeCellKit

class FavoriteAlbumTableViewCell: SwipeTableViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumDetailLabel: UILabel!
    
    var cell = FavoriteAlbumTableViewCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        albumImageView.layer.cornerRadius = 6.5
        albumImageView.clipsToBounds = true
    }
}
