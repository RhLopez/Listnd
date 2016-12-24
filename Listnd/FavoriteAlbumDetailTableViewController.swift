//
//  FavoriteAlbumDetailTableViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/19/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import SwiftMessages

protocol AlbumListenedDelegate: class {
    func albumListenedChange()
}

class FavoriteAlbumDetailTableViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let stack = CoreDataStack.sharedInstance
    var currentAlbum: Album!
    weak var albumListenedDelegate: AlbumListenedDelegate?
    
    // MARK: - View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            headerView.configureImageViews()
            if let data = currentAlbum.albumImage {
               headerView.imageTemplate.image = UIImage(data: data as Data)
            } else {
                headerView.imageTemplate.image = UIImage(named: "headerPlaceHolder")
            }
            headerView.nameLabel.text = currentAlbum.name
            headerView.addButton.isHidden = true
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            fetchTracks()
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Unable to load. Please try again.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tracksListened()
        stack.saveContext()
    }
    
    // MARK: - NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController<Track> = {
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Track.album.id), self.currentAlbum.id)
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
            SwiftMessages.sharedInstance.displayError(title: "Error", message: "Unable to retrieve track information.")
        }
    }
    
    func tracksListened() {
        var listenedCount = 0
        let tracks = fetchedResultsController.fetchedObjects!
        for track in tracks {
            if track.listened {
                listenedCount += 1
            }
        }
        currentAlbum.listenedCount = Int16(listenedCount)
        
        if listenedCount == fetchedResultsController.fetchedObjects?.count {
            if !currentAlbum.listened {
                currentAlbum.listened = true
                albumListenedDelegate?.albumListenedChange()
            }
        } else {
            if currentAlbum.listened {
                currentAlbum.listened = false
                albumListenedDelegate?.albumListenedChange()
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? FavoriteAlbumDetailTableViewcCell else { return }
        
        let track = fetchedResultsController.object(at: indexPath)
        cell.trackNameLabel.text = track.name
        
        let trackNumberText = track.trackNumber < 10 ? " \(track.trackNumber)." : "\(track.trackNumber)."
        cell.trackNumber.text = trackNumberText
        if track.listened {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
    }
    
    func deleteAction(indexPath: IndexPath) {
        let trackToDelete = fetchedResultsController.object(at: indexPath)
        stack.managedContext.delete(trackToDelete)
        stack.saveContext()
    }
    
    func listenedAction(indexPath: IndexPath)  {
        let track = fetchedResultsController.object(at: indexPath)
        track.listened = !track.listened
        stack.saveContext()
    }
    
    func openSpotifyAction(indexPath: IndexPath) {
        let track = fetchedResultsController.object(at: indexPath)
        let uriString = URL(string: track.uri)!
        UIApplication.shared.open(uriString, options: [:], completionHandler: nil)
    }
    
    func backButtonPressed(sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
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
}

// MARK: - UITableViewDelegate
extension FavoriteAlbumDetailTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        listenedAction(indexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (action, indexPath) in
            self.deleteAction(indexPath: indexPath)
            tableView.setEditing(false, animated: true)
        }
        
        let spotifyAction = UITableViewRowAction(style: .normal, title: "Spotify") { (action, indexPath) in
            self.openSpotifyAction(indexPath: indexPath)
            tableView.setEditing(false, animated: true)
        }
        
        deleteAction.backgroundColor = UIColor.red
        spotifyAction.backgroundColor = UIColor(red: 29/255, green: 185/255, blue: 84/255, alpha: 1)
        
        return [deleteAction, spotifyAction]
    }
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
