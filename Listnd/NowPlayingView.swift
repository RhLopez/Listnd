//
//  NowPlayingView.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 3/10/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class NowPlaying:UIView, AudioPlayerControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var scrubber: UISlider!
    
    var track: Track?
    var audioPlayer = AudioPlayer()
    
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        print("appearing")
//    }
    override func awakeFromNib() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { 
            self.songNameLabel.text = self.track!.name
            self.artistNameLabel.text = self.track!.album!.artist.name
            self.imageView.image = UIImage(data: self.track!.album!.albumImage as! Data)
            SPTAudioStreamingController.sharedInstance().playbackDelegate = self
        }
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        if SpotifyPlayer.isPlaying {
            if SPTAudioStreamingController.sharedInstance().playbackState.isPlaying {
                SPTAudioStreamingController.sharedInstance().setIsPlaying(false, callback: { (error) in
                    if error != nil {
                        print("There was an error pausing: \(error)")
                        return
                    }
                    SpotifyPlayer.isPaused = true
                    sender.setImage(#imageLiteral(resourceName: "mediaPlayButton"), for: .normal)
                })
            } else {
                SPTAudioStreamingController.sharedInstance().setIsPlaying(true, callback: { (error) in
                    if error != nil {
                        print("There was an error playing: \(error)")
                        return
                    }
                    SpotifyPlayer.isPaused = false
                    sender.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
                })
            }
        }
    }
    
    @IBAction func nowPlayingButtonPressed(_ sender: UIButton) {
        let audioVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AudioPlayer") as! AudioPlayer
        audioVC.currentTrack = track!
        audioVC.delegate = self
        let currentController = self.getCurrentViewController()
        currentController?.present(audioVC, animated: true, completion: nil)
    }
    
    func getCurrentViewController() -> UIViewController? {
        if let rootController = UIApplication.shared.keyWindow?.rootViewController {
            var currentController: UIViewController = rootController
            while (currentController.presentedViewController != nil) {
                currentController = currentController.presentedViewController!
            }
            return currentController
        }
        return nil
    }
    
    func trackDidUpdate(track: Track) {
        imageView.image = UIImage(data: track.album!.albumImage as! Data)
        songNameLabel.text = track.name
        artistNameLabel.text = track.album!.artist.name
    }
}

extension NowPlaying: SPTAudioStreamingPlaybackDelegate {
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        let duration = SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.duration
        scrubber.value = Float(position/duration)
    }
}
