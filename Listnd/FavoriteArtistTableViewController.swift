//
//  FavoriteTableViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import JSSAlertView
import SwipeCellKit
import Hero

class FavoriteArtistTableViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nowPlayingButton: UIButton!
    @IBOutlet weak var nowPlayingView: UIView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var mediaSlider: UISlider!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!

    
    
    // MARK: - Properties
    var coreDataStack: CoreDataStack!
    var selectedCell: IndexPath?
    var alertView: JSSAlertView!
    var premiumUser: Bool?
    public var heroNavigationAnimationType = HeroDefaultAnimationType.fade
    
    var nowPlayingTrack: Track?
    var nowPlaying: NowPlaying!

    
    // MARK: - View life cycle 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = selectedCell {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        if SpotifyPlayer.isPlaying {
            tableViewBottomConstraint.constant = 0.0
//            if let view = Bundle.main.loadNibNamed("NowPlaying", owner: self, options: nil)?.first as? NowPlaying {
//                nowPlayingView.addSubview(view)
//                nowPlayingView.isHidden = false
//            }
        } else {
            nowPlayingView.isHidden = true
            tableViewBottomConstraint.constant = CGFloat(-76)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if SpotifyPlayer.isPlaying {
            print("Time: \(SPTAudioStreamingController.sharedInstance().playbackState.position)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertView = JSSAlertView()
        fetchArtist()
        let userDefaults = UserDefaults()
        premiumUser = userDefaults.bool(forKey: "PremiumUser")
        if premiumUser! {
            try? SPTAudioStreamingController.sharedInstance().start(withClientId: "8faa83925ca64e5997e01122da55dcf0")
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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

    @IBAction func settingButtonPressed(_ sender: Any) {
        let settingVC = storyboard?.instantiateViewController(withIdentifier: "settingViewController") as! SettingViewController
        settingVC.modalPresentationStyle = .fullScreen
        settingVC.modalTransitionStyle = .coverVertical
        present(settingVC, animated: true, completion: nil)
    }
    
    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        if SPTAudioStreamingController.sharedInstance().playbackState.isPlaying {
            SPTAudioStreamingController.sharedInstance().setIsPlaying(false, callback: { (error) in
                if error != nil {
                    print("There was an error pausing: \(error)")
                    return
                }
                sender.setImage(#imageLiteral(resourceName: "mediaPlayButton"), for: .normal)
                SpotifyPlayer.isPaused = true
            })
        } else {
            SPTAudioStreamingController.sharedInstance().setIsPlaying(true, callback: { (error) in
                if error != nil {
                    print("There was an error playing: \(error)")
                    return
                }
                sender.setImage(#imageLiteral(resourceName: "mediaPauseButton"), for: .normal)
                SpotifyPlayer.isPaused = false
            })
        }
    }
}

// MARK: - Helper methods
extension FavoriteArtistTableViewController {
    func fetchArtist() {
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            alertView.danger(self, title: "Unable to load saved information", text: nil, buttonText: "Ok", cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? FavoriteArtistTableViewCell else { return }
        
        cell.delegate = self
        
        let artist = fetchedResultsController.object(at: indexPath)

        cell.artistNameLabel.text = artist.name
        cell.artistImageView.image = UIImage(named: "headerPlaceHolder")
        var albumCountMessage = ""
        if let count = artist.albums?.count {
            if count > 0 {
                albumCountMessage = count > 1 ? "\(count) Albums" : "\(count) Album"
            } else {
                albumCountMessage = "No Albums"
            }
        } else {
            albumCountMessage = ""
        }
        cell.albumCountLabel.text = albumCountMessage
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? AudioPlayer, let sender = sender as? UIButton {
            sender.heroID = "nowPlaying"
            vc.view.heroModifiers = [.source(heroID: "nowPlaying")]
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
}

// MARK: - UITableViewDelegate
extension FavoriteArtistTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumVC = storyboard?.instantiateViewController(withIdentifier: "favoriteAlbumTableView") as! FavoriteAlbumTableView
        albumVC.currentArtist = fetchedResultsController.object(at: indexPath)
        albumVC.coreDataStack = coreDataStack
        navigationController?.pushViewController(albumVC, animated: true)
        selectedCell = indexPath
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - SwipeTableViewCellDelegate
extension FavoriteArtistTableViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction] {
        guard orientation == .right else { return [] }
        
        let delete = SwipeAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let artistToDelete = self.fetchedResultsController.object(at: indexPath)
            self.coreDataStack.managedContext.delete(artistToDelete)
            self.coreDataStack.saveContext()
        }
        
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeTableOptions {
        var options = SwipeTableOptions()
        options.transitionStyle = .drag
        
        return options
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
            case .update, .move:
                tableView.deleteRows(at: [indexPath!], with: .automatic)
                tableView.insertRows(at: [newIndexPath!], with: .automatic)
            }
        }
    
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            tableView.endUpdates()
        }
}

extension FavoriteArtistTableViewController: SPTAudioStreamingPlaybackDelegate {
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        let duration = SPTAudioStreamingController.sharedInstance().metadata.currentTrack!.duration
        mediaSlider.value = Float(position/duration)
    }
}
