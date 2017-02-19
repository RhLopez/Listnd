//
//  AlbumDetailTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/9/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import AVFoundation
import SwipeCellKit

class AlbumDetailTableViewCell: SwipeTableViewCell {

    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var trackNumberLabel: UILabel!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var trackDurationLabel: UILabel!
    
    var playerItem: ListndPlayerItem?
}

