//
//  AlbumDetailViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/9/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import SwiftMessages

class AlbumDetailViewController: UIViewController, ListndPlayerItemDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var albumBackgoundImage: UIImageView!
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - Properties
    var stack = CoreDataStack.sharedInstance
    var currentAlbum: Album!
    var currentArtist: Artist!
    var tracks = [Track]()
    var savedTrackIds = [String]()
    var player = AVPlayer()
    var currentSong: IndexPath?
    var previousSelectedCell: IndexPath?
    var downloadingSampleClip: Bool?
    
    // MARK: - Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(playerFinishedPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 7, 0)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        setAudio()
        albumNameLabel.text = currentAlbum.name
        albumNameLabel.sizeToFit()
        albumImage.image = UIImage(named: "coverImagePlaceHolder")
        if let imageData = currentAlbum.albumImage {
            setAlbumImage(imageData: imageData)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(AlbumDetailViewController.albumImageDownloaded), name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: nil)
        }
        albumBackgoundImage.image = UIImage(named: "backgroundImage")
        getTracks()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        albumImage.layer.cornerRadius = 4.5
        albumImage.clipsToBounds = true
    }
    
    func playerReady() {
        downloadingSampleClip = false
        tableView.reloadRows(at: [currentSong!], with: .none)
    }
    
    func playerFinishedPlaying() {
        reloadRows(indexPath: currentSong!)
    }
}

// Mark: - Helper methods
extension AlbumDetailViewController {
    func setAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
        } catch {
            print("Audio Session could not be set")
        }
    }
    
    func getTracks() {
        ActivityIndicator.sharedInstance.showSearchingIndicator(tableView: tableView, view: self.view)
        SpotifyAPI.sharedInstance.getTracks(currentAlbum.id) { (success, results, errorMessage) in
            if success {
                if let searchResults = results {
                    self.tracks = searchResults
                    DispatchQueue.main.async {
                        ActivityIndicator.sharedInstance.hideSearchingIndicator()
                        self.tableView.reloadData()
                    }
                }
            } else {
                print(errorMessage!)
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? AlbumDetailTableViewCell else { return }

        let track = tracks[indexPath.row]
        cell.trackNameLabel.text = track.name
        cell.trackDurationLabel.text = timeConversion(duration: Int(track.duration))

        cell.playerItem = ListndPlayerItem(url: URL(string: track.previewURL!)!)
        cell.playerItem?.delegate = self
        
        if downloadingSampleClip == true && previousSelectedCell != indexPath {
            cell.activityIndicator.startAnimating()
            return
        }
        
        if currentSong == indexPath {
            cell.activityIndicator.stopAnimating()
            cell.trackImageView.image = UIImage(named: "stopButton")
            cell.trackNumberLabel.text = ""
            cell.trackNumberLabel.isHidden = true
            cell.trackImageView.isHidden = false
        }  else {
            if previousSelectedCell == indexPath {
                cell.activityIndicator.stopAnimating()
            }
            cell.trackImageView.isHidden = true
            cell.trackNumberLabel.isHidden = false
            cell.trackNumberLabel.text = track.trackNumber < 10 ? " \(track.trackNumber)." : "\(track.trackNumber)."
            
        }
    }
    
    func playSampleClip(indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! AlbumDetailTableViewCell

        if player.rate > 0 {
            player.pause()
        }
        
        if currentSong == nil || indexPath != currentSong! {
            downloadingSampleClip =  true
            player.replaceCurrentItem(with: cell.playerItem)
            player.play()
        }
        
        reloadRows(indexPath: indexPath)
    }
    
    func reloadRows(indexPath: IndexPath) {
        // Change button after another cell has been selected
        // from stackoverflow post http://stackoverflow.com/questions/27234684/how-to-change-previously-pressed-uibutton-label-in-uitableviewcell
        var rowsToReload = [NSIndexPath]()
        var stopCurrent = false
        if let _currenSong = currentSong {
            if indexPath == _currenSong {
                stopCurrent = true
            } else {
                rowsToReload.append((IndexPath(row: _currenSong.row, section: 0) as NSIndexPath))
            }
        }
        
        rowsToReload.append(IndexPath(row: indexPath.row, section: 0) as NSIndexPath)
        currentSong = stopCurrent ? nil : indexPath
        self.tableView.reloadRows(at: rowsToReload as [IndexPath], with: .none)
    }
    
    func saveSong(indexPath: IndexPath) {
        if let artist = fetchArtist() {
            if let album = fetchAlbum() {
                artist.addToAlbums(album)
                if let track = fetchTrack(indexPath: indexPath, album: album) {
                    album.addToTracks(track)
                    stack.saveContext()
                    let view = MessageView.viewFromNib(layout: .StatusLine)
                    view.configureTheme(.success)
                    view.configureDropShadow()
                    view.configureContent(body: "Song Saved!")
                    var config = SwiftMessages.Config()
                    config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
                    config.duration = .seconds(seconds: 0.5)
                    SwiftMessages.show(config: config, view: view)
                }
            }
        }
    }
    
    func fetchArtist() -> Artist? {
        let fetchRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Artist.id), currentAlbum.artist.id)
        fetchRequest.sortDescriptors = []
        
        do {
            let results = try stack.managedContext.fetch(fetchRequest)
            if results.count > 0 {
                currentArtist = results.first
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Artist", in: stack.managedContext)
                currentArtist = Artist(entity: entity!, insertInto: stack.managedContext)
                let artistSelected = currentAlbum.artist
                currentArtist!.name = artistSelected.name
                currentArtist!.id = artistSelected.id
                currentArtist!.imageURL = artistSelected.imageURL
                currentArtist!.artistImage = artistSelected.artistImage
                stack.saveContext()
            }
        } catch {
            print("Unable to fetch artist")
        }
        
        return currentArtist
    }
    
    func fetchAlbum() -> Album? {
        var album: Album?
        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Album.id), currentAlbum!.id)
        fetchRequest.sortDescriptors = []
        
        do {
            let results = try  stack.managedContext.fetch(fetchRequest)
            if results.count > 0 {
                album = results.first
                for item in (album?.tracks)! {
                    let track = item as! Track
                    savedTrackIds.append(track.id)
                }
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Album", in: stack.managedContext)!
                album = Album(entity: entity, insertInto: stack.managedContext)
                album!.name = currentAlbum.name
                album!.id = currentAlbum.id
                album!.imageURL = currentAlbum.imageURL
                album!.uri = currentAlbum.uri
                album!.albumImage = currentAlbum.albumImage
                album!.artist = currentArtist
                stack.saveContext()
            }
        } catch {
            print("Unable to fetch album")
        }
        return album
    }
    
    func fetchTrack(indexPath: IndexPath, album: Album)  -> Track? {
        var track: Track?
        let currentTrack = tracks[indexPath.row]
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Track.id), currentTrack.id)
        fetchRequest.sortDescriptors = []
        
        do {
            let results = try stack.managedContext.fetch(fetchRequest)
            if results.count > 0 {
                track = results.first
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Track", in: stack.managedContext)!
                track = Track(entity: entity, insertInto: stack.managedContext)
                track!.name = currentTrack.name
                track!.id = currentTrack.id
                track!.trackNumber = currentTrack.trackNumber
                track!.uri = currentTrack.uri
                track!.listened = currentTrack.listened
                track!.album = album
                stack.saveContext()
            }
        } catch {
            print("Unable to fetch track")
        }
        return track
    }
    
    func saveSongsFromAlbum(album: Album) {
        for track in tracks {
            if !savedTrackIds.contains(track.id) {
                let entity = NSEntityDescription.entity(forEntityName: "Track", in: stack.managedContext)!
                let trackToSave = Track(entity: entity, insertInto: stack.managedContext)
                trackToSave.name = track.name
                trackToSave.id = track.id
                trackToSave.trackNumber = track.trackNumber
                trackToSave.album = album
                trackToSave.uri = track.uri
                trackToSave.listened = track.listened
                album.addToTracks(trackToSave)
            }
        }
    }
    
    func timeConversion(duration: Int) -> String {
        let second = (duration / 1000) % 60
        let minute = (duration / (1000 * 60)) % 60
        
        return String(format: "%d:%02d", minute, second)
    }
    
    func albumImageDownloaded() {
        if let imageData = currentAlbum.albumImage {
            setAlbumImage(imageData: imageData)
        }
    }
    
    func setAlbumImage(imageData: NSData) {
        let image = UIImage(data: imageData as Data)
        UIView.transition(with: self.albumImage, duration: 1, options: .transitionCrossDissolve, animations: { self.albumImage.image = image }, completion: nil)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AlbumDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - IBAction
extension AlbumDetailViewController {
    @IBAction func saveAlbum() {
        if let artist = fetchArtist() {
            if  let album = fetchAlbum() {
                artist.addToAlbums(album)
                saveSongsFromAlbum(album: album)
                stack.saveContext()
                let view = MessageView.viewFromNib(layout: .StatusLine)
                view.configureTheme(.success)
                view.configureDropShadow()
                view.configureContent(body: "Album Saved!")
                var config = SwiftMessages.Config()
                config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
                config.duration = .seconds(seconds: 0.5)
                SwiftMessages.show(config: config, view: view)
            }
        }
    }
    
    @IBAction func backButtonPressed() {
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension AlbumDetailViewController: UITableViewDataSource {    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "songCell"
        let cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AlbumDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        previousSelectedCell = currentSong
        playSampleClip(indexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let saveSongAction = UITableViewRowAction(style: .normal, title: "Save") { (action, indexPath) in
            self.saveSong(indexPath: indexPath)
            tableView.setEditing(false, animated: true)
        }
        
        saveSongAction.backgroundColor = UIColor.blue
        return [saveSongAction]
    }
}
