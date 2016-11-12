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
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var artistImage: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    let stack = CoreDataStack.sharedInstance
    var currentArtist: Artist?

    
    // MARK: - View life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let artist = currentArtist {
            let image = UIImage(data: artist.artistImage! as Data)
            artistImage.image = image
            artistNameLabel.text = artist.name
            backgroundImage.image = UIImage(named: "backgroundImage")
            getAlbums()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        artistImage.layer.cornerRadius = 6.5
        artistImage.clipsToBounds = true
    }
    
    // MARK: - NSFetchedResultsController
        lazy var fetchedResultsController: NSFetchedResultsController<Album> = {
            let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(Album.artist.id), self.currentArtist!.id!)
            let sort = NSSortDescriptor(key: #keyPath(Album.name), ascending: true)
            fetchRequest.sortDescriptors = [sort]
            let fetchedResultsController = NSFetchedResultsController<Album>(fetchRequest: fetchRequest, managedObjectContext: self.stack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
    
            return fetchedResultsController
        }()
    
    @IBAction func backButtonPressed(_ sender: Any) {
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
        
        let image = UIImage(data: album.albumImage as! Data)!
        cell.albumImageView.image = image
        
        cell.albumDetailLabel.text = "\(album.tracks!.count) tracks"
    }
    
    func listenedSelected() {
        print("The album has been listened!")
    }
    
    func deleteAlbum(indexPath: IndexPath) {
        let albumToDelete = fetchedResultsController.object(at: indexPath)
        stack.managedContext.delete(albumToDelete)
        stack.saveContext()
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let listenedAction = UITableViewRowAction(style: .normal, title: "Listnd!") { (action, indexPath) in
            self.listenedSelected()
            tableView.setEditing(false, animated: true)
        }
        
        let deleteAction = UITableViewRowAction(style: .normal, title: "Delete") { (action, indexPath) in
            self.deleteAlbum(indexPath: indexPath)
            tableView.setEditing(false, animated: true)
        }
        
        listenedAction.backgroundColor = UIColor.blue
        deleteAction.backgroundColor = UIColor.red
        
        return [listenedAction, deleteAction]
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
