//
//  FavoriteArtistTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/15/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class FavoriteArtistTableViewCell: UITableViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    var cell = FavoriteAlbumTableViewCell.self {
        didSet {
            layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artistImageView.layer.cornerRadius = 6.5
        artistImageView.clipsToBounds = true
    }
    
}
