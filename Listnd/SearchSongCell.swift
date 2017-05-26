//
//  SearchSongCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/26/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class SearchSongCell: UITableViewCell {
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var songDetailLabel: UILabel!
    @IBOutlet weak var songArtistLabel: UILabel!
    
    func configure(withTrack track: AnyObject) {
        let song = track as! Track
        
        songNameLabel.text = song.name
        songDetailLabel.text = song.album!.name
        songArtistLabel.text = song.album!.artist!.name + " • Song"
    }
}
