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

class AudioPlayer: UIViewController, SPTAudioStreamingDelegate {
    
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
    var spotifyPlayer: SPTAudioStreamingController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        spotifyPlayer = SPTAudioStreamingController.sharedInstance()
        try! spotifyPlayer?.start(withClientId: "8faa83925ca64e5997e01122da55dcf0")
        spotifyPlayer?.delegate = self
        let userDefaults = UserDefaults()
        let sessionData = userDefaults.object(forKey: "SpotifySession")
        let authSession: SPTSession = NSKeyedUnarchiver.unarchiveObject(with: sessionData as! Data)! as! SPTSession
        if !authSession.isValid(){
            SPTAuth.defaultInstance().tokenRefreshURL = URL(string: "https://pacific-spire-64693.herokuapp.com/refresh")
            SPTAuth.defaultInstance().renewSession(authSession, callback: { (error, renewedSession) in
                if error != nil {
                    print("Error resfreshing session: \(error)")
                    return
                }
                
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: renewedSession!) as NSData
                userDefaults.set(sessionData, forKey: "SpotifySession")
                userDefaults.synchronize()
                self.spotifyPlayer?.login(withAccessToken: renewedSession!.accessToken!)
            })
        } else {
            spotifyPlayer?.login(withAccessToken: authSession.accessToken!)
        }
        currentTrack = currentAlbum.tracks!.object(at: indexPath.row) as! Track
        alertView = JSSAlertView()
        artistNameLabel.text = currentAlbum.artist.name
        albumNameLabel.text = currentAlbum.name
        songNameLabel.text = currentTrack.name
        let image = UIImage(data: currentAlbum.albumImage as! Data)
        albumCoverArt.image = image
        print("\(authSession.isValid())")
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        spotifyPlayer?.playSpotifyURI("\(currentTrack.uri)", startingWith: 0, startingWithPosition: 0) { (error) in
            if error != nil {
                print("Failed to play: \(error)")
                return
            }
            self.playPauseButton.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mediaSlider.setThumbImage(#imageLiteral(resourceName: "scrubberCircle"), for: .normal)
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
        if (spotifyPlayer?.playbackState.isPlaying)! {
            spotifyPlayer?.setIsPlaying(false, callback: { (error) in
                if error != nil {
                    print("There was an error pausing: \(error)")
                    return
                }
                
                self.playPauseButton.setImage(#imageLiteral(resourceName: "mediaPlayButton"), for: .normal)
            })
        } else {
            spotifyPlayer?.setIsPlaying(true, callback: { (error) in
                if error != nil {
                    print("There was an error playing: \(error)")
                    return
                }
                
                self.playPauseButton.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
            })
        }
    }
    @IBAction func sliderMoved(_ sender: UISlider) {
        player.seek(to: (CMTimeMake(Int64(sender.value), 1)))
    }
}
