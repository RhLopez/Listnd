//
//  ArtistDetailCollectionViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/8/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

class ArtistCollectionViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var artistCoverImage: UIImageView!
    @IBOutlet weak var artistBackgroundImage: UIImageView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: - Properties
    var stack = CoreDataStack.sharedInstance
    var currentArtist: Artist!
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // MARK: - Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deleteObjects()
        if let artist = currentArtist {
            let artistImage = UIImage(data: artist.artistImage as! Data)
            artistCoverImage.image = artistImage
            artistBackgroundImage.image = artistImage
            artistBackgroundImage.makeBlurImage(imageView: artistBackgroundImage)
            
            getAlbums(artistId: artist.id!)
            getCellSize()
        } else {
            print("Unable to get albums")
        }
    }
    
    // MARK: - FetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController<Album> = {
        let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Album.name), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        let fetchedResultsController = NSFetchedResultsController<Album>(fetchRequest: fetchRequest, managedObjectContext: self.stack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
}

// MARK: - Helper Method
extension ArtistCollectionViewController {
    func getCellSize() {
        let space: CGFloat = 1.0
        let dimension = (view.bounds.width - (2 * space)) / 2
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func getAlbums(artistId: String) {
        SpotifyAPI.sharedInstance.getAlbums(artistId) { (success, errorMessage) in
            if success {
                self.reloadCollectionView()
                let results = self.fetchedResultsController.fetchedObjects
                self.stack.managedContext.perform({ 
                    for album in results! {
                        album.artist = self.currentArtist
                    }
                    self.stack.saveContext()
                })
            } else {
                print(errorMessage)
            }
        }
    }
    
    func reloadCollectionView() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
        }
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func deleteObjects() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
        
        let count = try! stack.managedContext.count(for: fetchRequest)
        
        if count == 0 { return }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try stack.storeContainer.persistentStoreCoordinator.execute(deleteRequest, with: stack.managedContext)
        } catch let error as NSError {
            print("Unresolved error: \(error), \(error.userInfo)")
        }
    }
    
    func confirgureCell(cell: UICollectionViewCell, indexPath: IndexPath) {
        guard let cell = cell as? ArtistDetailCollectionViewCell else { return }
        
        cell.activityIndicatior.startAnimating()
        cell.albumImageView.image = UIImage(named: "placeHolder")
        
        let album = fetchedResultsController.object(at: indexPath)
        cell.albumNameLabel.text = album.name
        
        if album.albumImage == nil {
            if album.imageURL == "" {
                let image = UIImage(named: "noImage")
                let imageData = UIImagePNGRepresentation(image!)
                self.stack.managedContext.perform({ 
                    album.albumImage = NSData(data: imageData!)
                    self.stack.saveContext()
                })
                DispatchQueue.main.async {
                    cell.albumImageView.image = image
                    cell.activityIndicatior.stopAnimating()
                }
            } else {
                SpotifyAPI.sharedInstance.getImage(album.imageURL, completionHandlerForImage: { (data) in
                    if let resultData = data {
                        self.stack.managedContext.perform({ 
                            album.albumImage = NSData(data: resultData)
                            self.stack.saveContext()
                        })
                        let image = UIImage(data: resultData)
                        DispatchQueue.main.async {
                            cell.albumImageView.image = image
                            cell.activityIndicatior.stopAnimating()
                        }
                    }
                })
            }
        } else {
            let image = UIImage(data: album.albumImage as! Data)
            cell.albumImageView.image = image
            cell.activityIndicatior.stopAnimating()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ArtistCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifer = "albumCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifer, for: indexPath)
        confirgureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ArtistCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "AlbumDetailViewController") as! AlbumDetailViewController
        
        albumDetailVC.currentAlbum = fetchedResultsController.object(at: indexPath)
        navigationController?.pushViewController(albumDetailVC, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ArtistCollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            insertedIndexPaths.append(newIndexPath! as NSIndexPath)
            break
        case .delete:
            deletedIndexPaths.append(indexPath! as NSIndexPath)
            break
        case .update:
            updatedIndexPaths.append(indexPath! as NSIndexPath)
            break
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath as IndexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath as IndexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath as IndexPath])
            }
        }, completion: nil)
    }
}
