//
//  FavoriteAlbumDetailTableViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/19/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

class FavoriteAlbumDetailTableViewController: UIViewController {
    
    // MARK: - Properties
    let stack = CoreDataStack.sharedInstance
    var currentAlbum: Album!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = currentAlbum.name
        fetchTracks()
    }
    
    // MARK: - NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController<Track> = {
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Track.album.id), self.currentAlbum.id!)
        let sortDescriptor = NSSortDescriptor(key: #keyPath(Track.trackNumber), ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let fetchedResultsController = NSFetchedResultsController<Track>(fetchRequest: fetchRequest, managedObjectContext: self.stack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
}

// MARK: - Helper methods
extension FavoriteAlbumDetailTableViewController {
    func fetchTracks() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Unable to fetch tracks")
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? FavoriteAlbumDetailTableViewcCell else { return }
        
        let track = fetchedResultsController.object(at: indexPath)
        cell.trackNameLabel.text = track.name
        
        let trackNumberText = track.trackNumber < 10 ? " \(track.trackNumber)." : "\(track.trackNumber)."
        cell.trackNumber.text = trackNumberText
    }
}

// MARK: - UIGestureRecognizerDelegate
extension FavoriteAlbumDetailTableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UITableViewDataSource
extension FavoriteAlbumDetailTableViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "trackCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let trackToDelete = fetchedResultsController.object(at: indexPath)
            stack.managedContext.delete(trackToDelete)
            stack.saveContext()
        }
    }
}

// MARK: - UITableViewDelegate
extension FavoriteAlbumDetailTableViewController {
    
}

// MARK: - NSFetchedResultsControllerDelegate
extension FavoriteAlbumDetailTableViewController: NSFetchedResultsControllerDelegate {
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
            let cell = tableView.cellForRow(at: indexPath!) as! FavoriteAlbumDetailTableViewcCell
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
