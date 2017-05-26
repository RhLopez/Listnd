//
//  AlbumTableViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/16/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftMessages

class AlbumTableViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var currentArtist: Artist!
    var artistImageFrame: UIImageView!
    var headerView: HeaderView!
    var selectedCell: IndexPath?
    var albums: List<Album>?
    var notificationToken: NotificationToken? = nil
    
    // MARK: - View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        if let indexPath = selectedCell {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView, let artist = currentArtist {
            self.headerView = headerView
            headerView.configureView(name: artist.name, imageData: artist.image as Data?, hideButton: true)
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(_:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            registerNib()
            getAlbums()
            subscribeNotificationToken()
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Unable to load. Please try again")
        }
    }
    
    deinit {
        notificationToken?.stop()
    }
}

// MARK: - Helper methods
extension AlbumTableViewController {
    func registerNib() {
        let albumNib = UINib(nibName: "AlbumCell", bundle: nil)
        tableView.register(albumNib, forCellReuseIdentifier: "albumCell")
    }
    
    func subscribeNotificationToken() {
        notificationToken = albums?.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
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
    
    func getAlbums() {
        albums = currentArtist.albums
    }
    
    func openSpotify(indexPath: IndexPath) {
        let album = albums![indexPath.row]
        let urlString = URL(string: album.uri)!
        if UIApplication.shared.canOpenURL(urlString) {
            UIApplication.shared.open(urlString, options: [:], completionHandler: nil)
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
    
    func backButtonPressed(_ sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}

// UIGestureRecognizerDelegate
extension AlbumTableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension AlbumTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "albumCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! AlbumCell
        let album = albums![indexPath.row]
        cell.configure(with: album)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AlbumTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "albumDetailTableView") as! AlbumDetailTableViewController
        albumDetailVC.currentAlbum = albums![indexPath.row]
        albumDetailVC.albumListenedDelegate = self
        navigationController?.pushViewController(albumDetailVC, animated: true)
        selectedCell = indexPath   
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let spotify = UITableViewRowAction(style: .normal, title: "Spotify") { (action, indexPath) in
            self.openSpotify(indexPath: indexPath)
            self.tableView.isEditing = false
        }
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let realm = try! Realm()
            let album = self.albums![indexPath.row]
            try! realm.write {
                for track in album.tracks {
                    realm.delete(track)
                }
                realm.delete(album)
            }
        }
        
        spotify.backgroundColor = UIColor(red: 29/255, green: 185/255, blue: 84/255, alpha: 1)
        
        return [delete, spotify]
    }
}

extension AlbumTableViewController: AlbumListenedDelegate {
    func albumListenedChange() {
        let realm = try! Realm()
        var listenedCount = 0
        var hasListened = false
        for album in albums! {
            if album.listened {
                listenedCount += 1
            }
        }

        if listenedCount == albums!.count {
            hasListened = true
        } else {
            hasListened = false
        }
        
        try! realm.write {
            currentArtist.listened = hasListened
        }
    }
}
