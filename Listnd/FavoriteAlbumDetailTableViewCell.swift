//
//  FavoriteAlbumDetailTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/19/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class FavoriteAlbumDetailTableViewcCell: UITableViewCell {
    
    @IBOutlet weak var trackNumber: UILabel!
    @IBOutlet weak var trackNameLabel: UILabel!
    
    func configure(with track: Track) {
        self.trackNameLabel.text = track.name
        
        let trackNumberText = track.trackNumber < 10 ? " \(track.trackNumber)." : "\(track.trackNumber)."
        self.trackNumber.text = trackNumberText
        if track.listened {
            self.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            self.accessoryType = UITableViewCellAccessoryType.none
        }
    }
}
