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
    var coreDataStack: CoreDataStack!
    var selectedCell: IndexPath?
    
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
        fetchArtist()
    }
    
     //MARK: - FetchedResultsController
        lazy var fetchedResultsController: NSFetchedResultsController<Artist> = {
            let fetchRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
            let sort = NSSortDescriptor(key: #keyPath(Artist.name), ascending: true)
            fetchRequest.sortDescriptors = [sort]
             let fetchedResultsController = NSFetchedResultsController<Artist>(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
    
            return fetchedResultsController
        }()
}

// MARK: - Helper methods
extension FavoriteArtistTableViewController {
    func registerNib() {
        let artistNib = UINib(nibName: "ArtistCell", bundle: nil)
        tableView.register(artistNib, forCellReuseIdentifier: "artistCell")
    }
    
    func fetchArtist() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Unable to load saved information")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! ArtistCell
        let artist = fetchedResultsController.object(at: indexPath)
        cell.configure(with: artist)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FavoriteArtistTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumVC = storyboard?.instantiateViewController(withIdentifier: "favoriteAlbumTableView") as! FavoriteAlbumTableView
        albumVC.coreDataStack = coreDataStack
        albumVC.currentArtist = fetchedResultsController.object(at: indexPath)
        navigationController?.pushViewController(albumVC, animated: true)
        selectedCell = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            let artistToDelete = self.fetchedResultsController.object(at: indexPath)
            self.coreDataStack.managedContext.delete(artistToDelete)
            self.coreDataStack.saveContext()
        }
        
        delete.backgroundColor = .red
        
        return [delete]
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
                let cell = tableView.dequeueReusableCell(withIdentifier: "artistCell", for: indexPath!) as! ArtistCell
                let artist = fetchedResultsController.object(at: indexPath!)
                cell.configure(with: artist)
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
