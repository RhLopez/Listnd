//
//  SearchTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/4/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var searchImageVIew: UIImageView!
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var cell = SearchTableViewCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        searchImageVIew.layer.cornerRadius = 6.5
        searchImageVIew.clipsToBounds = true
    }
}
