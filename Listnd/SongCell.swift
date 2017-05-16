//
//  SongCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 5/15/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell {
    
    @IBOutlet weak var songNumber: UILabel!
    @IBOutlet weak var songName: UILabel!

    func configure(with track: Track) {
        self.songName.text = track.name
        
        let trackNumberText = track.trackNumber < 10 ? " \(track.trackNumber)." : "\(track.trackNumber)."
        self.songNumber.text = trackNumberText
        if track.listened {
            self.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            self.accessoryType = UITableViewCellAccessoryType.none
        }
    }
}
