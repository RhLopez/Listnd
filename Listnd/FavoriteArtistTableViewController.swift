//
//  FavoriteTableViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import SwiftMessages

class FavoriteArtistTableViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let stack = CoreDataStack.sharedInstance
    var selectedCell: IndexPath?
    
    // MARK: - View life cycle 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = selectedCell {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        fetchArtist()
    }
    
     //MARK: - FetchedResultsController
        lazy var fetchedResultsController: NSFetchedResultsController<Artist> = {
            let fetchRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
            let sort = NSSortDescriptor(key: #keyPath(Artist.name), ascending: true)
            fetchRequest.sortDescriptors = [sort]
             let fetchedResultsController = NSFetchedResultsController<Artist>(fetchRequest: fetchRequest, managedObjectContext: self.stack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
    
            return fetchedResultsController
        }()
}

// MARK: - Helper methods
extension FavoriteArtistTableViewController {
    func fetchArtist() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Unable to load saved information.")
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? FavoriteArtistTableViewCell else { return }
        
        let artist = fetchedResultsController.object(at: indexPath)

        cell.artistNameLabel.text = artist.name
        cell.artistImageView.image = UIImage(named: "headerPlaceHolder")
        
        if artist.listened {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        // Get album image if the album was saved prior to image being saved due to slow connetcion
        if let data = artist.artistImage {
            cell.artistImageView.image = UIImage(data: data as Data)
        } else {
            getAlbumImage(url: artist.imageURL, completetionHandlerForAlbumImage: { (data) in
                let image = UIImage(data: data as Data)
                UIView.transition(with: cell.artistImageView, duration: 1, options: .transitionCrossDissolve, animations: { cell.artistImageView.image = image }, completion: nil)
                artist.artistImage = data
            })
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
            let image = UIImage(named: "headerPlaceHolder")
            let data = UIImagePNGRepresentation(image!)!
            completetionHandlerForAlbumImage(data as NSData)
        }
    }
}

// MARK: - UITableViewDataSouce
extension FavoriteArtistTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifer = "artistCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let artistToDelete = fetchedResultsController.object(at: indexPath)
            stack.managedContext.delete(artistToDelete)
            stack.saveContext()
        }
    }
}

// MARK: - UITableViewDelegate
extension FavoriteArtistTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumVC = storyboard?.instantiateViewController(withIdentifier: "favoriteAlbumTableView") as! FavoriteAlbumTableView
        albumVC.currentArtist = fetchedResultsController.object(at: indexPath)
        navigationController?.pushViewController(albumVC, animated: true)
        selectedCell = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NSFecthedResultsControllerDelegate
extension FavoriteArtistTableViewController: NSFetchedResultsControllerDelegate {
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
                let cell = tableView.cellForRow(at: indexPath!) as! FavoriteArtistTableViewCell
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
