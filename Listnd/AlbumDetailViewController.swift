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
import SVProgressHUD
import GSKStretchyHeaderView

class AlbumDetailViewController: UIViewController, ListndPlayerItemDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var stack = CoreDataStack.sharedInstance
    var currentAlbum: Album!
    var currentArtist: Artist!
    var tracks = [Track]()
    var savedTrackIds = [String]()
    var player = AVPlayer()
    var currentIndexPath: IndexPath?
    var previousSelectedCell: IndexPath?
    var downloadingSampleClip: Bool?
    var isLoading: Bool?
    var headerView: HeaderView!
    
    // MARK: - Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            self.headerView = headerView
            headerView.configureImageViews()
            headerView.imageTemplate.image = UIImage(named: "headerPlaceHolder")
            if let imageData = currentAlbum.albumImage {
                setAlbumImage(imageData: imageData)
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(AlbumDetailViewController.albumImageDownloaded), name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: nil)
            }
            headerView.nameLabel.text = currentAlbum.name
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            headerView.addButton.addTarget(self, action: #selector(saveAlbum), for: .touchUpInside)
            tableView.addSubview(headerView)
            NotificationCenter.default.addObserver(self, selector: #selector(playerFinishedPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            setAudio()
            getTracks()
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "There was an error loading the album detail. Please try again.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: nil)
        if isLoading == true {
            SVProgressHUD.dismiss()
        }
    }
    
    func playerReady() {
        downloadingSampleClip = false
        if let indexPath = currentIndexPath {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func playerFinishedPlaying() {
        if let indexPath = currentIndexPath {
            reloadRows(indexPath: indexPath)
        }
    }
}

// Mark: - Helper methods
extension AlbumDetailViewController {
    func setAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
        } catch {
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "Audio session could not be set")
        }
    }
    
    func getTracks() {
        isLoading = true
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Loading...")
        SpotifyAPI.sharedInstance.getTracks(currentAlbum.id) { (results, errorMessage) in
            if let searchResults = results {
                self.tracks = searchResults
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.tableView.reloadData()
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    SwiftMessages.sharedInstance.displayError(title: "Error", message: errorMessage)
                }
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? AlbumDetailTableViewCell else { return }

        let track = tracks[indexPath.row]
        cell.trackNameLabel.text = track.name
        cell.trackDurationLabel.text = timeConversion(duration: Int(track.duration))

        if let url = track.previewURL {
            cell.playerItem = ListndPlayerItem(url: URL(string: url)!)
            cell.playerItem?.delegate = self
        } else {
            cell.playerItem = nil
        }
        
        if downloadingSampleClip == true && previousSelectedCell != indexPath {
            cell.trackImageView.isHidden = true
            cell.trackNumberLabel.isHidden = true
            cell.activityIndicator.startAnimating()
            return
        }
        
        if currentIndexPath == indexPath {
            cell.activityIndicator.stopAnimating()
            cell.trackImageView.image = UIImage(named: "stopButton")
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
        
        if cell.playerItem != nil {
            if player.rate > 0 {
                player.pause()
            }
            
            if currentIndexPath == nil || indexPath != currentIndexPath {
                downloadingSampleClip =  true
                player.replaceCurrentItem(with: cell.playerItem)
                player.play()
            }
            
            reloadRows(indexPath: indexPath)
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Unable to preview song")
        }
    }
    
    func reloadRows(indexPath: IndexPath) {
        // Change button after another cell has been selected
        // from stackoverflow post http://stackoverflow.com/questions/27234684/how-to-change-previously-pressed-uibutton-label-in-uitableviewcell
        var rowsToReload = [NSIndexPath]()
        var stopCurrent = false
        if let _currenSong = currentIndexPath {
            if indexPath == _currenSong {
                stopCurrent = true
            } else {
                rowsToReload.append((IndexPath(row: _currenSong.row, section: 0) as NSIndexPath))
            }
        }
        
        rowsToReload.append(IndexPath(row: indexPath.row, section: 0) as NSIndexPath)
        currentIndexPath = stopCurrent ? nil : indexPath
        self.tableView.reloadRows(at: rowsToReload as [IndexPath], with: .none)
    }
    
    func saveSong(indexPath: IndexPath) {
        if let artist = fetchArtist() {
            if let album = fetchAlbum() {
                artist.addToAlbums(album)
                if let track = fetchTrack(indexPath: indexPath, album: album) {
                    album.addToTracks(track)
                    stack.saveContext()
                    SwiftMessages.sharedInstance.displayConfirmation(message: "Song Saved!")
                } else {
                    SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Song previously saved")
                }
            } else {
                SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Song previously saved")
            }
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "Unable to save song. Please try again.")
        }
    }
    
    func saveAlbum() {
        if let artist = fetchArtist() {
            if  let album = fetchAlbum() {
                artist.addToAlbums(album)
                saveSongsFromAlbum(album: album)
                stack.saveContext()
                SwiftMessages.sharedInstance.displayConfirmation(message: "Album Saved!")
            } else {
                SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Album previously saved")
            }
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "Unable to save album. Please try again.")
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
                currentArtist.listened = artistSelected.listened
                stack.saveContext()
            }
        } catch {
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "There was an error retrieving saved artist information")
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
                if album?.tracks?.count == tracks.count {
                    album = nil
                } else {
                    for item in (album?.tracks)! {
                        let track = item as! Track
                        savedTrackIds.append(track.id)
                    }
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
                album!.listened = currentAlbum.listened
                album!.listenedCount = currentAlbum.listenedCount
                stack.saveContext()
            }
        } catch {
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "There was an error retrieving saved album information")
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
                track = nil
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
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "There was an error retrieving saved song information")
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
        UIView.transition(with: self.headerView.imageTemplate, duration: 1, options: .transitionCrossDissolve, animations: { self.headerView.imageTemplate.image = image }, completion: nil)
    }
    
    func backButtonPressed(sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AlbumDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
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
        if Reachability.sharedInstance.isConnectedToNetwork() {
            previousSelectedCell = currentIndexPath
            playSampleClip(indexPath: indexPath)
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "Unable to play song. \nNo internet connection detected.")
        }
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
