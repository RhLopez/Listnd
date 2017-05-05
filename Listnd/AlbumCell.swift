//
//  AlbumCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/25/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class AlbumCell: UITableViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumDetailLabel: UILabel!
    
    var cell = AlbumCell.self {
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
