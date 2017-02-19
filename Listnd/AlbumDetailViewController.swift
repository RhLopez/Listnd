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
import SVProgressHUD
import GSKStretchyHeaderView
import JSSAlertView
import SwipeCellKit

class AlbumDetailViewController: UIViewController, ListndPlayerItemDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var coreDataStack: CoreDataStack!
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
    var alertView: JSSAlertView!
    
    // MARK: - Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertView = JSSAlertView()
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            self.headerView = headerView
            headerView.configureView(name: currentAlbum.name, imageData: currentAlbum.albumImage as? Data, hideButton: false)
            if currentAlbum.albumImage == nil {
                NotificationCenter.default.addObserver(self, selector: #selector(AlbumDetailViewController.albumImageDownloaded), name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: nil)
            }
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            headerView.addButton.addTarget(self, action: #selector(saveAlbum), for: .touchUpInside)
            tableView.addSubview(headerView)
            NotificationCenter.default.addObserver(self, selector: #selector(playerFinishedPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            setAudio()
            getTracks()
        } else {
            alertView.danger(self, title: "There was an error loading the album detail\n.Please try again", text: nil, buttonText: "Ok", cancelButtonText: nil, delay: nil, timeLeft: nil)
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
            alertView.danger(self, title: "Audio session could not be set", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
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
                    self.alertView.danger(self, title: errorMessage, text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
                }
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? AlbumDetailTableViewCell else { return }
        
        cell.delegate = self
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
            alertView.danger(self, title: "Unable to preview song", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
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
                    coreDataStack.saveContext()
                    alertView.show(self, title: "Song Saved", text: nil, noButtons: true, buttonText: nil, cancelButtonText: nil, color: UIColorFromHex(0xD3D2D3, alpha: 1), iconImage: nil, delay: 0.2, timeLeft: nil)
                } else {
                    alertView.danger(self, title: "Song previously saved", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
                }
            } else {
                alertView.danger(self, title: "Song previously saved", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
            }
        } else {
            alertView.danger(self, title: "Unable to save song. Please try again.", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
    }
    
    func saveAlbum() {
        if let artist = fetchArtist() {
            if  let album = fetchAlbum() {
                artist.addToAlbums(album)
                saveSongsFromAlbum(album: album)
                coreDataStack.saveContext()
                alertView.show(self, title: "Album Saved", text: nil, noButtons: true, buttonText: nil, cancelButtonText: nil, color: UIColorFromHex(0xD3D2D3, alpha: 1), iconImage: nil, delay: 0.2, timeLeft: nil)
            } else {
                alertView.danger(self, title: "Album previously saved", text: nil, buttonText: "Ok", cancelButtonText: nil, delay: nil, timeLeft: nil)
            }
        } else {
            alertView.danger(self, title: "Unable to save album", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
    }
    
    func fetchArtist() -> Artist? {
        let fetchRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Artist.id), currentAlbum.artist.id)
        fetchRequest.sortDescriptors = []
        
        do {
            let results = try coreDataStack.managedContext.fetch(fetchRequest)
            if results.count > 0 {
                currentArtist = results.first
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Artist", in: coreDataStack.managedContext)
                currentArtist = Artist(entity: entity!, insertInto: coreDataStack.managedContext)
                let artistSelected = currentAlbum.artist
                currentArtist!.name = artistSelected.name
                currentArtist!.id = artistSelected.id
                currentArtist!.imageURL = artistSelected.imageURL
                currentArtist!.artistImage = artistSelected.artistImage
                currentArtist.listened = artistSelected.listened
                coreDataStack.saveContext()
            }
        } catch {
            alertView.danger(self, title: "There was an error retrieving saved artist information", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
        
        return currentArtist
    }
    
    func fetchAlbum() -> Album? {
        var album: Album?
        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Album.id), currentAlbum!.id)
        fetchRequest.sortDescriptors = []
        
        do {
            let results = try  coreDataStack.managedContext.fetch(fetchRequest)
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
                let entity = NSEntityDescription.entity(forEntityName: "Album", in: coreDataStack.managedContext)!
                album = Album(entity: entity, insertInto: coreDataStack.managedContext)
                album!.name = currentAlbum.name
                album!.id = currentAlbum.id
                album!.imageURL = currentAlbum.imageURL
                album!.uri = currentAlbum.uri
                album!.albumImage = currentAlbum.albumImage
                album!.artist = currentArtist
                album!.listened = currentAlbum.listened
                album!.listenedCount = currentAlbum.listenedCount
            }
        } catch {
            alertView.danger(self, title: "There was an error retrieving saved album information", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
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
            let results = try coreDataStack.managedContext.fetch(fetchRequest)
            if results.count > 0 {
                track = nil
            } else {
                let entity = NSEntityDescription.entity(forEntityName: "Track", in: coreDataStack.managedContext)!
                track = Track(entity: entity, insertInto: coreDataStack.managedContext)
                track!.name = currentTrack.name
                track!.id = currentTrack.id
                track!.trackNumber = currentTrack.trackNumber
                track!.uri = currentTrack.uri
                track!.listened = currentTrack.listened
                track!.album = album
                coreDataStack.saveContext()
            }
        } catch {
            alertView.danger(self, title: "There was an error retrieving saved song information", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
        return track
    }
    
    func saveSongsFromAlbum(album: Album) {
        for track in tracks {
            if !savedTrackIds.contains(track.id) {
                let entity = NSEntityDescription.entity(forEntityName: "Track", in: coreDataStack.managedContext)!
                let trackToSave = Track(entity: entity, insertInto: coreDataStack.managedContext)
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
            headerView.setImage(data: imageData as Data)
        }
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
            alertView.danger(self, title: "Unable to play song.\nNo internet connection detected", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - SwipeTableViewCellDelegate
extension AlbumDetailViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction] {
        guard orientation == .right else { return [] }
        
        let save = SwipeAction(style: .default, title: "Save") { (action, indexPath) in
            self.saveSong(indexPath: indexPath)
        }
        
        save.backgroundColor = UIColor.blue
        
        return [save]
    }
}
