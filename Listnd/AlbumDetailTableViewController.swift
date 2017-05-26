//
//  AlbumDetailTableViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/19/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftMessages

protocol AlbumListenedDelegate: class {
    func albumListenedChange()
}

class AlbumDetailTableViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var currentAlbum: Album!
    var tracks: List<Track>!
    var notificationToken: NotificationToken? = nil
    weak var albumListenedDelegate: AlbumListenedDelegate?
    
    // MARK: - View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            headerView.configureView(name: currentAlbum.name, imageData: currentAlbum.artworkImage as Data?, hideButton: true)
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            registerNib()
            fetchTracks()
            subscribeNotificationToken()
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Unable to load album detail")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tracksListened()
    }
    
    deinit {
        notificationToken?.stop()
    }
}

// MARK: - Helper methods
extension AlbumDetailTableViewController {
    func registerNib() {
        let songNib = UINib(nibName: "SongCell", bundle: nil)
        tableView.register(songNib, forCellReuseIdentifier: "songCell")
    }
    
    func fetchTracks() {
        tracks = currentAlbum.tracks
    }
    
    func subscribeNotificationToken() {
        notificationToken = tracks.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
                break
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
                break
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
                break
            }
        }
    }
    
    func tracksListened() {
        var listenedCount = 0
        var hasListened = false
        
        for track in tracks {
            if track.listened {
                listenedCount += 1
            }
        }
        
        if listenedCount == tracks.count {
            hasListened = true
        }
        
        let realm = try! Realm()
        try! realm.write {
            currentAlbum.listened = hasListened
            currentAlbum.listenedCount = listenedCount
        }
        albumListenedDelegate?.albumListenedChange()
    }
    
    func listenedAction(indexPath: IndexPath)  {
        let track = tracks[indexPath.row]
        let realm = try! Realm()
        try! realm.write {
            track.listened = !track.listened
        }
    }
    
    func openSpotifyAction(indexPath: IndexPath) {
        let track = tracks[indexPath.row]
        let uriString = URL(string: track.uri)!
        if UIApplication.shared.canOpenURL(uriString) {
            UIApplication.shared.open(uriString, options: [:], completionHandler: nil)
        } else {
            let alertController = UIAlertController(title: "Attention", message: "Spotify application was not found.\nWould you like to install it?", preferredStyle: .alert)
            let installAction = UIAlertAction(title: "Install", style: .default, handler: { (action) in
                if let url = URL(string: "https://itunes.apple.com/us/app/spotify-music/id324684580?mt=8") {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(installAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func backButtonPressed(sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AlbumDetailTableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension AlbumDetailTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "songCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! SongCell
        let track = tracks[indexPath.row]
        cell.configure(with: track)
        return cell
    }
}

// MArk: - UITableViewDelegate
extension AlbumDetailTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        listenedAction(indexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let spotifyAction = UITableViewRowAction(style: .normal, title: "Spotify") { (action, indexPath) in
            self.openSpotifyAction(indexPath: indexPath)
            self.tableView.isEditing = false
        }
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let realm = try! Realm()
            let track = self.tracks[indexPath.row]
            try! realm.write {
                realm.delete(track)
            }
        }
        
        spotifyAction.backgroundColor = UIColor(red: 29/255, green: 185/255, blue: 84/255, alpha: 1)
        
        return [deleteAction, spotifyAction]
    }
}
