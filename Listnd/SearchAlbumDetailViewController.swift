//
//  SearchAlbumDetailViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/9/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import AVFoundation
import RealmSwift
import SVProgressHUD
import GSKStretchyHeaderView
import SwiftMessages

class SearchAlbumDetailViewController: UIViewController, ListndPlayerItemDelegate {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var currentAlbum: Album!
    var albumId: String?
    var tracks = [Track]()
    var savedTrackIds = [String]()
    var player = AVPlayer()
    var currentIndexPath: IndexPath?
    var previousSelectedCell: IndexPath?
    var downloadingSampleClip: Bool?
    var isLoading: Bool?
    var headerView: HeaderView!
    var songId: String?
    
    // MARK: - Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let id = albumId {
            getMissingAlbum(albumId: id)
        } else {
            configureUI()
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
    
    func getMissingAlbum(albumId id: String) {
        getAlbum(albumId: id, completionHander: { (success, errorMessage) in
            if success {
                DispatchQueue.main.async {
                    self.configureUI()
                }
            } else {
                print(errorMessage!)
            }
        })
    }
    
    func getAlbum(albumId id:String, completionHander: @escaping(_ success: Bool, _ errorMessage: String?) -> Void) {
        SpotifyAPI.sharedInstance.getAlbum(id) { (result, errorMessage) in
            if let album = result {
                self.currentAlbum = album
                self.getAlbumImage(withURL: self.currentAlbum.artworkUrl)
                completionHander(true, nil)
            } else {
                completionHander(false, errorMessage)
            }
        }
    }
    
    func getAlbumImage(withURL url: String?) {
        SpotifyAPI.sharedInstance.getImage(url) { (data) in
            if let imageData = data {
                self.currentAlbum.artworkImage = NSData(data: imageData)
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: self)
                }
            } else {
                let image = UIImage(named: "headerPlaceHolder")
                let data = UIImagePNGRepresentation(image!)!
                self.currentAlbum.artworkImage = NSData(data: data)
            }
        }
    }
    
    func getArtistImageUrl(_ id: String) {
        SpotifyAPI.sharedInstance.getImageURL(currentAlbum.artist!.id) { (url) in
            if let imageURL = url {
                self.currentAlbum.artist!.imageURL = imageURL
                self.getArtistImage(url: imageURL, completetionHandlerForAlbumImage: { (data) in
                    self.currentAlbum.artist!.image = data
                })
            }
        }
    }
    
    func getArtistImage(url: String?, completetionHandlerForAlbumImage: @escaping (_ imageData: NSData) -> Void) {
        if let urlString = url {
            SpotifyAPI.sharedInstance.getImage(urlString, completionHandlerForImage: { (result) in
                if let data = result {
                    completetionHandlerForAlbumImage(data as NSData)
                }
            })
        } else {
            let image = UIImage(named: "headerPlaceHolder")
            let data = UIImagePNGRepresentation(image!)!
            completetionHandlerForAlbumImage(data as NSData)
        }
    }
    
    func configureUI() {
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            self.headerView = headerView
            headerView.configureView(name: currentAlbum.name, imageData: currentAlbum.artworkImage as Data?, hideButton: false)
            if currentAlbum.artworkImage == nil {
                NotificationCenter.default.addObserver(self, selector: #selector(SearchAlbumDetailViewController.albumImageDownloaded), name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: nil)
            }
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            headerView.addButton.addTarget(self, action: #selector(saveAlbum), for: .touchUpInside)
            tableView.addSubview(headerView)
            NotificationCenter.default.addObserver(self, selector: #selector(playerFinishedPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            setAudio()
            getTracks()
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "There was an error loading the album detail\nPlease try again.")
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
extension SearchAlbumDetailViewController {
    func setAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
        } catch {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Audio session could not be set")
        }
    }
    
    func getTracks() {
        isLoading = true
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Loading...")
        SpotifyAPI.sharedInstance.getTracks(currentAlbum.id) { (results, errorMessage) in
            if let searchResults = results {
                self.tracks = searchResults
                for track in self.tracks {
                    self.currentAlbum.tracks.append(track)
                }
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.tableView.reloadData()
                    self.isLoading = false
                    self.getArtistImageUrl(self.currentAlbum.artist!.id)
                }
            } else {
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    SwiftMessages.sharedInstance.displayError(title: "Alert", message: errorMessage)
                }
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? AlbumDetailTableViewCell else { return }
        
        let track = tracks[indexPath.row]
        cell.trackNameLabel.text = track.name
        if let id = songId {
            if track.id == id {
                cell.trackNameLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
            }
        }
        cell.trackDurationLabel.text = timeConversion(duration: Int(track.duration))

        if let url = track.previewUrl {
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
    
    func saveAlbum() {
        let realm = try! Realm()
        
        if let _ = realm.object(ofType: Album.self, forPrimaryKey: currentAlbum.id) {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Album previously saved")
        } else {
            let artist = checkArtist(forAlbum: currentAlbum)
            let album = currentAlbum!
            try! realm.write {
                currentAlbum.artist = nil
                artist.albums.append(album)
                realm.add(artist, update: true)
                SwiftMessages.sharedInstance.displayConfirmation(message: "Album saved")
            }
        }
    }
    
    func saveSong(forIndexPath indexPath: IndexPath) {
        let realm = try! Realm()
        let track = tracks[indexPath.row]
        if let _ = realm.object(ofType: Track.self, forPrimaryKey: track.id) {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Song previously saved")
        } else {
            let artist = checkArtist(forAlbum: currentAlbum)
            let album = checkAlbum(currentAlbum)
            try! realm.write {
                album.artist = nil
                track.album = nil
                if !albumExist(album.id) {
                    artist.albums.append(album)
                    album.tracks.removeAll()
                }
                album.tracks.append(track)
                realm.add(artist, update: true)
                SwiftMessages.sharedInstance.displayConfirmation(message: "Song saved")
            }
        }
    }
    
    func checkArtist(forAlbum album: Album) -> Artist {
        let realm = try! Realm()
        let artist: Artist!
        
        if let savedArist = realm.object(ofType: Artist.self, forPrimaryKey: album.artist!.id) {
            artist = savedArist
        } else {
            artist = Artist.clone(currentAlbum.artist!)
        }
        
        return artist
    }
    
    func checkAlbum(_ album: Album) -> Album {
        let realm = try! Realm()
        let checkedAlbum: Album!
        
        if let savedAlbum = realm.object(ofType: Album.self, forPrimaryKey: album.id) {
            checkedAlbum = savedAlbum
        } else {
            checkedAlbum = currentAlbum!
        }
        
        return checkedAlbum
    }
    
    func albumExist(_ id: String) -> Bool {
        let realm = try! Realm()
        return realm.object(ofType: Album.self, forPrimaryKey: id) != nil ? true : false
    }
    
    func timeConversion(duration: Int) -> String {
        let second = (duration / 1000) % 60
        let minute = (duration / (1000 * 60)) % 60
        
        return String(format: "%d:%02d", minute, second)
    }
    
    func albumImageDownloaded() {
        if let imageData = currentAlbum.artworkImage {
            headerView.setImage(data: imageData as Data)
        }
    }
    
    func backButtonPressed(sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SearchAlbumDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension SearchAlbumDetailViewController: UITableViewDataSource {
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
extension SearchAlbumDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if Reachability.sharedInstance.isConnectedToNetwork() {
            previousSelectedCell = currentIndexPath
            playSampleClip(indexPath: indexPath)
        } else {
            SwiftMessages.sharedInstance.displayError(title: "No internet connection dectected", message: "Unable to play song")
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let save = UITableViewRowAction(style: .default, title: "Save") { (action, indexPath) in
            self.saveSong(forIndexPath: indexPath)
            self.tableView.isEditing = false
        }
        
        save.backgroundColor = .blue
        
        return [save]
    }
}
