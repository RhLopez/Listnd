//
//  AlbumDetailViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/9/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class AlbumDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var albumBackgoundImage: UIImageView!
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var stack = CoreDataStack.sharedInstance
    var currentAlbum: Album!
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var currentSong: Int?
    var isPlaying: Bool?
    
    // MARK: - Lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        setAudio()
        deleteObjects()
        let image = UIImage(data: (currentAlbum.albumImage as? Data)!)
        albumImage.image = image
        albumBackgoundImage.image = image
        albumBackgoundImage.makeBlurImage(imageView: albumBackgoundImage)
        getTracks()
    }
    
    // MARK: - NSFetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController<Track> = {
        let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(Track.trackNumber), ascending: true)
        fetchRequest.sortDescriptors = [sort]
        let fetchedResultsController = NSFetchedResultsController<Track>(fetchRequest: fetchRequest, managedObjectContext: self.stack.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
}

// Mark: - Helper methods
extension AlbumDetailViewController {
    func setAudio() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
        } catch {
            print("Audio Session could not be set")
        }
    }
    
    func getTracks() {
        SpotifyAPI.sharedInstance.getTracks(currentAlbum.id!) { (success, errorMessage) in
            if success {
                self.reloadTableView()
            } else {
                print(errorMessage)
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? AlbumDetailTableViewCell else { return }
        
        let track = fetchedResultsController.object(at: indexPath)
        cell.trackNameLabel.text = track.name
        let trackNumbetText = track.trackNumber < 10 ? " \(track.trackNumber)." : "\(track.trackNumber)."
        cell.trackNumberLabel.text = trackNumbetText
    }
    
    func deleteObjects() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
        
        let count = try! stack.managedContext.count(for: fetchRequest)
        
        if count == 0 { return }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try stack.storeContainer.persistentStoreCoordinator.execute(deleteRequest, with: stack.managedContext)
        } catch let error as NSError {
            print("Unresolved error: \(error), \(error.userInfo)")
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
    
    func playSampleClip(indexPath: IndexPath) {
        let track = fetchedResultsController.object(at: indexPath)
        if let urlString = track.previewURL {
            playerItem = AVPlayerItem(url: URL(string: urlString)!)
            player = AVPlayer(playerItem: playerItem!)
            player!.play()
        } else {
            print("Unable to play selected song")
        }
    }
    
    func saveSong(indexPath: IndexPath) {
        print("Saving song")
    }
}

// MARK: - UITableViewDataSource
extension AlbumDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "songCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        return
    }
}

// MARK: - UITableViewDelegate
extension AlbumDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        playSampleClip(indexPath: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let saveSongAction = UITableViewRowAction(style: .normal, title: "Save") { (action, indexPath) in
            self.saveSong(indexPath: indexPath)
            tableView.setEditing(false, animated: true)
        }
        
        saveSongAction.backgroundColor = UIColor.blue
        return [saveSongAction]
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension AlbumDetailViewController: NSFetchedResultsControllerDelegate {
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
            let cell = tableView.cellForRow(at: indexPath!) as! AlbumDetailTableViewCell
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
