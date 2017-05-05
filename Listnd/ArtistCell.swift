//
//  ArtistCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/25/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class ArtistCell: UITableViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var albumCountLabel: UILabel!
    
    var cell = ArtistCell.self {
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
