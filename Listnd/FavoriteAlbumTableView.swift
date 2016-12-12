//
//  FavoriteAlbumTableView.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/16/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import SwiftMessages

class FavoriteAlbumTableView: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let stack = CoreDataStack.sharedInstance
    var currentArtist: Artist?
    var artistImageFrame: UIImageView!
    var headerView: HeaderView!
    var selectedCell: IndexPath?

    lazy var listenedCountPredicate: NSPredicate = {
        return NSPredicate(format: "%K == %@", #keyPath(Track.listened), true as CVarArg)
    }()
    
    // MARK: - View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        if let cell = selectedCell {
            tableView.reloadRows(at: [cell], with: .automatic)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView, let artist = currentArtist {
            self.headerView = headerView
            headerView.configureImageViews()
            if let data = artist.artistImage {
               headerView.imageTemplate.image = UIImage(data: data as Data)
            } else {
                headerView.imageTemplate.image = UIImage(named: "coverImagePlaceHolder")
            }
            headerView.nameLabel.text = artist.name
            headerView.addButton.isHidden = true
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(_:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            getAlbums()
        }
    }
    
    // MARK: - NSFetchedResultsController
        lazy var fetchedResultsController: NSFetchedResultsController<Album> = {
            let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Album.artist.id), self.currentArtist!.id)
            let sort = NSSortDescriptor(key: #keyPath(Album.name), ascending: true)
            fetchRequest.sortDescriptors = [sort]
            let fetchedResultsController = NSFetchedResultsController<Album>(fetchRequest: fetchRequest, managedObjectContext: self.stack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
    
            return fetchedResultsController
        }()
    
    func backButtonPressed(_ sender: UIButton) {
       _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - Helper method
extension FavoriteAlbumTableView {
    func getAlbums() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Unable to fetch albums")
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? FavoriteAlbumTableViewCell else { return }
        
        let album = fetchedResultsController.object(at: indexPath)
        cell.albumNameLabel.text = album.name
        cell.albumImageView.image = UIImage(named: "coverImagePlaceHolder")
        
        // Get album image if the album was saved prior to image being saved due to slow connetcion
        if let data = album.albumImage {
            cell.albumImageView.image = UIImage(data: data as Data)
        } else {
            getAlbumImage(url: album.imageURL, completetionHandlerForAlbumImage: { (data) in
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: cell.albumImageView, duration: 1, options: .transitionCrossDissolve, animations: { cell.albumImageView.image = image }, completion: nil)
                    album.albumImage = data
                    self.stack.saveContext()
                }
            })
        }
        
        let count = getListenedCount(indexPath: indexPath)
        cell.albumDetailLabel.text = "\(count) of \(album.tracks!.count) Tracks Lisntd"
        
        if count == album.tracks!.count {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
    }
    
    func getAlbumImage(url: String?, completetionHandlerForAlbumImage: @escaping (_ imageData: NSData) -> Void) {
        if let urlString = url {
            SpotifyAPI.sharedInstance.getImage(urlString, completionHandlerForImage: { (result) in
                if let data = result {
                    completetionHandlerForAlbumImage(data as NSData)
                }
            })
        } else {
            let image = UIImage(named: "coverImagePlaceHolder")
            let data = UIImagePNGRepresentation(image!)!
            completetionHandlerForAlbumImage(data as NSData)
        }
    }
    
    func getListenedCount(indexPath: IndexPath) -> Int {
        var count = 0
        let album = fetchedResultsController.object(at: indexPath)
        if let tracks = album.tracks {
            for item in tracks {
                let track = item as! Track
                if track.listened {
                    count = count + 1
                }
            }
        }
        
        return count
    }
        
    func deleteAlbum(indexPath: IndexPath) {
        let albumToDelete = fetchedResultsController.object(at: indexPath)
        stack.managedContext.delete(albumToDelete)
        stack.saveContext()
    }
    
    func openSpotify(indexPath: IndexPath) {
        let album = fetchedResultsController.object(at: indexPath)
        let urlString = URL(string: album.uri)!
        if UIApplication.shared.canOpenURL(urlString) {
            UIApplication.shared.open(urlString, options: [:], completionHandler: nil)
        } else {
            SwiftMessages.sharedInstance.displayCustomMessage()
        }
    }
}

// UIGestureRecognizerDelegate
extension FavoriteAlbumTableView: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension FavoriteAlbumTableView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "albumCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FavoriteAlbumTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "albumDetailTableView") as! FavoriteAlbumDetailTableViewController
        albumDetailVC.currentAlbum = fetchedResultsController.object(at: indexPath)
        navigationController?.pushViewController(albumDetailVC, animated: true)
        selectedCell = indexPath   
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let openSpotifyAction = UITableViewRowAction(style: .normal, title: "Spotify") { (action, indexPath) in
            self.openSpotify(indexPath: indexPath)
            tableView.setEditing(false, animated: true)
        }
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (action, indexPath) in
            self.deleteAlbum(indexPath: indexPath)
            tableView.setEditing(false, animated: true)
        }
        
        openSpotifyAction.backgroundColor = UIColor(red: 29/255, green: 185/255, blue: 84/255, alpha: 1)
        deleteAction.backgroundColor = UIColor.red
        
        return [deleteAction, openSpotifyAction]
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension FavoriteAlbumTableView: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            let cell = tableView.cellForRow(at: indexPath!) as! FavoriteAlbumTableViewCell
            configureCell(cell: cell, indexPath: indexPath!)
            break
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
