//
//  FavoriteAlbumTableView.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/16/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

class FavoriteAlbumTableView: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var coreDataStack: CoreDataStack!
    var currentArtist: Artist!
    var artistImageFrame: UIImageView!
    var headerView: HeaderView!
    var selectedCell: IndexPath?
    
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
            headerView.configureView(name: artist.name, imageData: artist.artistImage as Data?, hideButton: true)
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(_:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            getAlbums()
        } else {
            //alertView.danger(self, title: "Unable to load. Please try again", text: nil, buttonText: "Ok", cancelButtonText: nil, delay: nil, timeLeft: nil)

        }
    }
        
    // MARK: - NSFetchedResultsController
        lazy var fetchedResultsController: NSFetchedResultsController<Album> = {
            let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Album.artist.id), self.currentArtist!.id)
            let sort = NSSortDescriptor(key: #keyPath(Album.name), ascending: true)
            fetchRequest.sortDescriptors = [sort]
            let fetchedResultsController = NSFetchedResultsController<Album>(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
    
            return fetchedResultsController
        }()
}

// MARK: - Helper methods
extension FavoriteAlbumTableView {
    func getAlbums() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            //alertView.danger(self, title: "Unable to load information", text: nil, buttonText: "Ok", cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
    }
    
    func deleteAlbum(indexPath: IndexPath) {
        let albumToDelete = fetchedResultsController.object(at: indexPath)
        coreDataStack.managedContext.delete(albumToDelete)
        coreDataStack.saveContext()
    }
    
    func openSpotify(indexPath: IndexPath) {
        let album = fetchedResultsController.object(at: indexPath)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! FavoriteAlbumTableViewCell
        let album = fetchedResultsController.object(at: indexPath)
        cell.configure(with: album)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FavoriteAlbumTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "albumDetailTableView") as! FavoriteAlbumDetailTableViewController
        albumDetailVC.coreDataStack = coreDataStack
        albumDetailVC.currentAlbum = fetchedResultsController.object(at: indexPath)
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
            self.deleteAlbum(indexPath: indexPath)
        }
        
        spotify.backgroundColor = UIColor(red: 29/255, green: 185/255, blue: 84/255, alpha: 1)
        
        return [delete, spotify]
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
            let album = fetchedResultsController.object(at: indexPath!)
            cell.configure(with: album)
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

extension FavoriteAlbumTableView: AlbumListenedDelegate {
    func albumListenedChange() {
        var listenedCount = 0
        let albums = fetchedResultsController.fetchedObjects!
        for album in albums {
            if album.listened {
                listenedCount += 1
            }
        }
        
        if listenedCount == fetchedResultsController.fetchedObjects?.count {
            if !currentArtist.listened {
                currentArtist.listened = true
            }
        } else {
            if currentArtist.listened {
                currentArtist.listened = false
            }
        }
        
        coreDataStack.saveContext()
    }
}
