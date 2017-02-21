//
//  AudioPlayer.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 2/19/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import AVFoundation

class AudioPlayer: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumCoverArt: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    // MARK: - Properties
    var currentAlbum: Album!
    var player: AVPlayer!
    var indexPath: IndexPath!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        artistNameLabel.text = currentAlbum.artist.name
        albumNameLabel.text = currentAlbum.name
        
        let image = UIImage(data: currentAlbum.albumImage as! Data)
        albumCoverArt.image = image
        
        
        
    }
}
