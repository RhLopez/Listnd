//
//  ArtistTableViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftMessages

class ArtistTableViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var selectedCell: IndexPath?
    var artists: Results<Artist>?
    var notificationToken: NotificationToken? = nil
    
    // MARK: - View life cycle 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        if let indexPath = selectedCell {
//            tableView.reloadRows(at: [indexPath], with: .automatic)
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        registerNib()
        getArtists()
        subscribeNotificationToken()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    deinit {
        notificationToken?.stop()
    }
}

// MARK: - Helper methods
extension ArtistTableViewController {
    func registerNib() {
        let artistNib = UINib(nibName: "ArtistCell", bundle: nil)
        tableView.register(artistNib, forCellReuseIdentifier: "artistCell")
    }
    
    func getArtists() {
        let realm = try? Realm()
        artists = realm?.objects(Artist.self)
    }
    
    func subscribeNotificationToken() {
        notificationToken = artists?.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
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
}

// MARK: - UITableViewDataSouce
extension ArtistTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifer = "artistCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! ArtistCell
        let artist = artists![indexPath.row]
        cell.configure(with: artist)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ArtistTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumVC = storyboard?.instantiateViewController(withIdentifier: "favoriteAlbumTableView") as! AlbumTableViewController
        albumVC.currentArtist = artists![indexPath.row]
        navigationController?.pushViewController(albumVC, animated: true)
        selectedCell = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            let realm = try! Realm()
            let artist = self.artists![indexPath.row]
            
            try! realm.write {
                for album in artist.albums {
                    for track in album.tracks {
                        realm.delete(track)
                    }
                    realm.delete(album)
                }
                realm.delete(artist)
            }
        }
        
        delete.backgroundColor = .red
        
        return [delete]
    }
}
