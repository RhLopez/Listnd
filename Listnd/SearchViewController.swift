//
//  SearchViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    let coreDataStack = CoreDataStack.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = true
        searchBar.delegate = self
        
    }

    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? SearchTableViewCell else {
            return
        }
        cell.searchImageVIew.image = UIImage(named: "placeHolder")
        cell.activityIndicator.startAnimating()
        let artist = fetchedResultsController.object(at: indexPath)
        cell.searchLabel.text = artist.name
        
        if artist.artistImage == nil {
            if artist.imageURL == "" {
                let image = UIImage(named: "noImage")
                let imageData = UIImagePNGRepresentation(image!)!
                self.coreDataStack.managedContext.perform({ 
                    artist.artistImage = NSData(data: imageData)
                    self.coreDataStack.saveContext()
                })
                DispatchQueue.main.async {
                    cell.searchImageVIew.image = image
                    cell.activityIndicator.stopAnimating()
                }
            } else {
                SpotifyAPI.sharedInstance.getImage(artist.imageURL!) { (data) in
                    if let resultData = data {
                        self.coreDataStack.managedContext.perform({ 
                            artist.artistImage = NSData(data: resultData)
                            self.coreDataStack.saveContext()
                        })
                        let image = UIImage(data: resultData)
                        DispatchQueue.main.async {
                            cell.searchImageVIew?.image = image
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                }
            }
        } else {
            let image = UIImage(data: artist.artistImage as! Data)
            cell.searchImageVIew?.image = image
            cell.activityIndicator.stopAnimating()
        }
    }
    
    // Enable UISearchBar cancel button after calling resignFirstResponder
    // from stackoverflow post http://stackoverflow.com/questions/27020452/enable-cancel-button-with-uisearchbar-in-ios8
    func enableCancelButton(searchBar: UISearchBar) {
        for view1 in searchBar.subviews {
            for view2 in view1.subviews {
                if view2.isKind(of: UIButton.self) {
                    let button = view2 as! UIButton
                    button.isEnabled = true
                    button.isUserInteractionEnabled = true
                }
            }
        }
    }
    
    func reloadTableView() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func deleteObjects() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
        
        let count = try! coreDataStack.managedContext.count(for: fetchRequest)

        if count == 0 { return }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try coreDataStack.storeContainer.persistentStoreCoordinator.execute(deleteRequest, with: coreDataStack.managedContext)
        } catch let error as NSError {
            print("Unresolved error: \(error), \(error.userInfo)")
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController<Artist> = {
        let fetchRequest: NSFetchRequest<Artist> = Artist.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Artist.resultNumber), ascending: true)
        fetchRequest.sortDescriptors = [sort]
         let fetchedResultsController = NSFetchedResultsController<Artist>(fetchRequest: fetchRequest, managedObjectContext: self.coreDataStack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        enableCancelButton(searchBar: searchBar)
        deleteObjects()
        SpotifyAPI.sharedInstance.searchArtist(searchBar.text!) { (success, errorMessage) in
            if success {
                self.reloadTableView()
            } else {
                print(errorMessage)
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: true)
        deleteObjects()
        reloadTableView()
    }
}

extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "searchCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
}

extension SearchViewController: NSFetchedResultsControllerDelegate {
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
            let cell = tableView.cellForRow(at: indexPath!) as! SearchTableViewCell
            configureCell(cell: cell, indexPath: indexPath!)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
