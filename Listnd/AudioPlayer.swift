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
import Hero

protocol AudioPlayerControllerDelegate: class {
    func trackDidUpdate(track: Track)
}

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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentPosition: UILabel!
    @IBOutlet weak var timeRemaining: UILabel!

    
    // MARK: - Properties
    var currentAlbum: Album!
    var indexPath: IndexPath!
    var currentTrack: Track?
    var alertView: JSSAlertView!
    var dateComponentsFormatter: DateComponentsFormatter!
    var player: SPTAudioStreamingController?
    
    weak var delegate: AudioPlayerControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.allowedUnits = [.minute, .second]
        dateComponentsFormatter.zeroFormattingBehavior = .pad
        setUpSpotify()
        mediaSlider.setThumbImage(#imageLiteral(resourceName: "scrubberCircle"), for: .normal)
        alertView = JSSAlertView()
        artistNameLabel.text = currentTrack?.album!.artist.name
        albumNameLabel.text = currentTrack?.album!.name
        songNameLabel.text = currentTrack?.name
        let image = UIImage(data: currentTrack?.album!.albumImage as! Data)
        albumCoverArt.image = image
        playPauseButton.setImage(#imageLiteral(resourceName: "blankPlayPauseButton"), for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if SpotifyPlayer.isPlaying {
            playPauseButton.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.1) {
            self.mediaSlider.alpha = 0
        }
    }
    
    func setUpSpotify() {
        if !SpotifyPlayer.isPlaying {
            activityIndicator.startAnimating()
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
                    SPTAudioStreamingController.sharedInstance().login(withAccessToken: renewedSession!.accessToken!)
                })
            } else {
                SPTAudioStreamingController.sharedInstance().login(withAccessToken: authSession.accessToken!)
            }
        } else {
            let duration = SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.duration
            let position = SPTAudioStreamingController.sharedInstance().playbackState.position
            mediaSlider.value = Float(position/duration)
            let timeLeft = position - duration
            currentPosition.text = dateComponentsFormatter.string(from: position)
            timeRemaining.text = dateComponentsFormatter.string(from: timeLeft)
        }
        SPTAudioStreamingController.sharedInstance().delegate = self
        SPTAudioStreamingController.sharedInstance().playbackDelegate = self
        playPauseButton.setImage(#imageLiteral(resourceName: "mediaPlayButton"), for: .normal)
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        if !SpotifyPlayer.isPlaying {
            SPTAudioStreamingController.sharedInstance().playSpotifyURI("\(currentTrack!.uri)", startingWith: 0, startingWithPosition: 0) { (error) in
                if error != nil {
                    print("Failed to play: \(error)")
                    return
                }
                self.activityIndicator.stopAnimating()
                self.playPauseButton.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
                SpotifyPlayer.isPlaying = true
                SpotifyPlayer.trackURI = (self.currentTrack?.uri)!
                self.delegate?.trackDidUpdate(track: self.currentTrack!)
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
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
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        // TODO: Implement scrubbing
    }
    
    func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

extension AudioPlayer: SPTAudioStreamingPlaybackDelegate {
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        let duration = SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.duration
        mediaSlider.value = Float(position/duration)

        let timeLeft = position - duration
        currentPosition.text = dateComponentsFormatter.string(from: position)
        timeRemaining.text = dateComponentsFormatter.string(from: timeLeft)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            activateAudioSession()
        } else {
            deactivateAudioSession()
        }
    }
}
