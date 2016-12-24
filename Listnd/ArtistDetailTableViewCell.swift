//
//  ArtistDetailTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/17/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class ArtistDetailTableViewCell: UITableViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var cell = ArtistDetailTableViewCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        albumImageView.layer.cornerRadius = 4.0
        albumImageView.clipsToBounds = true
    }
}
