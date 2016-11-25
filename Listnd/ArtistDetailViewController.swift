//
//  ArtistDetailViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/17/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

let albumImageDownloadNotification = "com.RhL.albumImageNotificationKey"

class ArtistDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var stack = CoreDataStack.sharedInstance
    var currentArtist: Artist!
    var sections = [String]()
    var searchItems = [[Album]]()
    var albumIndex: Int?
    var singleIndex: Int?
    var selectedRow: IndexPath?
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        artistNameLabel.text = currentArtist.name
        artistImageView.image = UIImage(named: "coverImagePlaceHolder")
        if let imageData = currentArtist.artistImage {
            setArtistImage(imageData: imageData)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(ArtistDetailViewController.artistImageDownloaded), name: NSNotification.Name(rawValue: artistImageDownloadNotification), object: nil)
        }
        backgroundImageView.image = UIImage(named: "backgroundImage")
        getAlbums(artistId: currentArtist.id)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        artistImageView.layer.cornerRadius = 6.5
        artistImageView.clipsToBounds = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: artistImageDownloadNotification), object: nil)
    }
}

//MARK: - Helper methods
extension ArtistDetailViewController {
    func getAlbums(artistId: String) {
        ActivityIndicator.sharedInstance.showSearchingIndicator(tableView: tableView, view: self.view)
        SpotifyAPI.sharedInstance.getAlbums(artistId) { (results, errorMessage) in
            if let searchResults = results {
                for album in searchResults {
                    album.artist = self.currentArtist
                    if album.type == "single" {
                        if self.sections.isEmpty {
                            self.sections.append("Single")
                            self.singleIndex = 0
                            self.albumIndex = 1
                        }
                        if !self.sections.contains("Single") {
                            self.sections.append("Single")
                        }
                        if self.searchItems.isEmpty || self.searchItems.count == 1 {
                            self.searchItems.append([album])
                        } else {
                            self.searchItems[self.singleIndex!].append(album)
                        }
                    } else if album.type == "album" {
                        if self.sections.isEmpty {
                            self.sections.append("Album")
                            self.albumIndex = 0
                            self.singleIndex = 1
                        }
                        if !self.sections.contains("Album") {
                            self.sections.append("Album")
                        }
                        if self.searchItems.isEmpty {
                            self.searchItems.append([album])
                        } else {
                            self.searchItems[self.albumIndex!].append(album)
                        }
                    }
                }
                DispatchQueue.main.async {
                    ActivityIndicator.sharedInstance.hideSearchingIndicator()
                    self.tableView.reloadData()
                }
            } else {
                print(errorMessage)
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? ArtistDetailTableViewCell else { return }
        
        cell.albumImageView.image = UIImage(named: "placeHolder")
        
        let album = searchItems[indexPath.section][indexPath.row]
        cell.albumNameLabel.text = album.name
        
        if album.albumImage == nil {
            if album.imageURL == "" {
                let image = UIImage(named: "noImage")!
                let imageData = UIImagePNGRepresentation(image)!
                album.albumImage = NSData(data: imageData)
                DispatchQueue.main.async {
                    cell.albumImageView.image = image
                }
            } else {
                SpotifyAPI.sharedInstance.getImage(album.imageURL, completionHandlerForImage: { (result) in
                    if let data = result {
                        album.albumImage = NSData(data: data)
                        if self.selectedRow == indexPath {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: self)
                        }
                        let image = UIImage(data: data)
                        DispatchQueue.main.async {
                            UIView.transition(with: cell.albumImageView, duration: 1, options: .transitionCrossDissolve, animations: { cell.albumImageView.image = image }, completion: nil)
                        }
                    }
                })
            }
        } else {
            let image = UIImage(data: album.albumImage as! Data)
            cell.albumImageView.image = image
            cell.activityIndicator.stopAnimating()
        }
    }
    
    func artistImageDownloaded() {
        if let imageData = currentArtist.artistImage {
            setArtistImage(imageData: imageData)
        }
    }
    
    func setArtistImage(imageData: NSData) {
        let image = UIImage(data: imageData as Data)
        UIView.transition(with: self.artistImageView, duration: 1, options: .transitionCrossDissolve, animations: { self.artistImageView.image = image }, completion: nil)
    }
}

// MARK: - IBAction
extension ArtistDetailViewController {
    @IBAction func backButtonPressed() {
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ArtistDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "artistCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        configureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
}


// MARK: - UITableViewDelegate
extension ArtistDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "AlbumDetailViewController") as! AlbumDetailViewController
        
        albumDetailVC.currentAlbum = searchItems[indexPath.section][indexPath.row]
        selectedRow = indexPath
        navigationController?.pushViewController(albumDetailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ArtistDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
