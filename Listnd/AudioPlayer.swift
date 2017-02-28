//
//  AudioPlayer.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 2/19/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import AVFoundation
import JSSAlertView

class AudioPlayer: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumCoverArt: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var mediaSlider: UISlider!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    // MARK: - Properties
    var currentAlbum: Album!
    var player = AVPlayer()
    var indexPath: IndexPath!
    var currentTrack: Track!
    var alertView: JSSAlertView!
    var playerItem: ListndPlayerItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentTrack = currentAlbum.tracks!.object(at: indexPath.row) as! Track
        alertView = JSSAlertView()
        artistNameLabel.text = currentAlbum.artist.name
        albumNameLabel.text = currentAlbum.name
        songNameLabel.text = currentTrack.name
        let image = UIImage(data: currentAlbum.albumImage as! Data)
        albumCoverArt.image = image
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaSlider.setThumbImage(#imageLiteral(resourceName: "scrubberCircle"), for: .normal)
        let url = URL(string: currentTrack.previewURL!)!
        playerItem = ListndPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        //mediaSlider.maximumValue = Float(CMTimeGetSeconds(player.currentItem!.asset.duration))
        player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1/30.0, Int32(NSEC_PER_SEC)), queue: nil) { (time) in
            self.mediaSlider.value = Float(CMTimeGetSeconds(time))
        }
        player.play()
        playPauseButton.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
    }
    
    func setAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
        } catch {
            alertView.danger(self, title: "Audio session could not be set", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        if player.rate > 0 {
            playPauseButton.setImage(#imageLiteral(resourceName: "mediaPlayButton"), for: .normal)
            player.pause()
        } else {
            playPauseButton.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
            player.play()
        }
    }
    @IBAction func sliderMoved(_ sender: UISlider) {
        player.seek(to: (CMTimeMake(Int64(sender.value), 1)))
    }
}
