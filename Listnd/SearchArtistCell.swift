//
//  SearchArtistCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/30/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class SearchArtistCell: UITableViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    var cell = SearchArtistCell.self {
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
