//
//  ArtistDetailViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/17/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import SwiftMessages
import SVProgressHUD
import GSKStretchyHeaderView

// MARK: - Notification key
let albumImageDownloadNotification = "com.RhL.albumImageNotificationKey"

class ArtistDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var stack = CoreDataStack.sharedInstance
    var currentArtist: Artist!
    var sections = [String]()
    var searchItems = [[Album]]()
    var albumIndex: Int?
    var singleIndex: Int?
    var selectedRow: IndexPath?
    var isLoading: Bool?
    var headerView: HeaderView!
    var fetchingAlbums = true
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            self.headerView = headerView
            headerView.configureImageViews()
            headerView.imageTemplate.image = UIImage(named: "headerPlaceHolder")
            if let imageData = currentArtist.artistImage {
                setArtistImage(imageData: imageData)
            } else {
                NotificationCenter.default.addObserver(self, selector: #selector(ArtistDetailViewController.artistImageDownloaded), name: NSNotification.Name(rawValue: artistImageDownloadNotification), object: nil)
            }
            headerView.nameLabel.text = currentArtist.name
            headerView.addButton.isHidden = true
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
            getAlbums(artistId: currentArtist.id)
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "There was an error loading the artist detail. Please try again.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: artistImageDownloadNotification), object: nil)
        if isLoading == true {
            SVProgressHUD.dismiss()
        }
    }
}

//MARK: - Helper methods
extension ArtistDetailViewController {
    func getAlbums(artistId: String) {
        isLoading = true
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Loading...")
        SpotifyAPI.sharedInstance.getAlbums(artistId) { (results, errorMessage) in
            self.fetchingAlbums = false
            if let searchResults = results {
                if !searchResults.isEmpty {
                   self.processAlbumSections(albums: searchResults)
                }
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.tableView.reloadData()
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    let messageView = MessageView.viewFromNib(layout: .TabView)
                    messageView.configureTheme(.error)
                    messageView.configureContent(title: "Error", body: errorMessage)
                    SwiftMessages.show(view: messageView)
                }
            }
        }
    }
    
    func processAlbumSections(albums: [Album]) {
        for album in albums {
            album.artist = self.currentArtist
            if album.type == "single" {
                if !sections.contains("Single") {
                    sections.append("Single")
                    singleIndex = sections.index(of: "Single")
                }
                if searchItems.isEmpty || (sections[0] == "Album" && searchItems.count == 1) {
                    searchItems.append([album])
                } else {
                    searchItems[singleIndex!].append(album)
                }
            } else if album.type == "album" {
                if !sections.contains("Album") {
                    sections.append("Album")
                    albumIndex = sections.index(of: "Album")
                }
                if searchItems.isEmpty || (sections[0] == "Single" && searchItems.count == 1){
                    searchItems.append([album])
                } else {
                    searchItems[albumIndex!].append(album)
                }
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? ArtistDetailTableViewCell else { return }
        
        cell.albumImageView.image = UIImage(named: "thumbnailPlaceHolder")
        
        let album = searchItems[indexPath.section][indexPath.row]
        cell.albumNameLabel.text = album.name
        
        if let data = album.albumImage {
            let image = UIImage(data: data as Data)
            cell.albumImageView.image = image
        } else {
            getAlbumImage(url: album.imageURL, completetionHandlerForAlbumImage: { (data) in
                album.albumImage = NSData(data: data as Data)
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: cell.albumImageView, duration: 1, options: .transitionCrossDissolve, animations: { cell.albumImageView.image = image }, completion: nil)
                    if self.selectedRow == indexPath {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: albumImageDownloadNotification), object: self)
                    }
                }
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
    
    func artistImageDownloaded() {
        if let imageData = currentArtist.artistImage {
            setArtistImage(imageData: imageData)
        }
    }
    
    func setArtistImage(imageData: NSData) {
        let image = UIImage(data: imageData as Data)
        UIView.transition(with: self.headerView.imageTemplate, duration: 1, options: .transitionCrossDissolve, animations: { self.headerView.imageTemplate.image = image }, completion: nil)
    }
    
    func backButtonPressed(sender: UIButton) {
        _ = navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ArtistDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if fetchingAlbums {
            return 0
        } else if searchItems.isEmpty {
            return 1
        } else {
            return sections.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchItems.isEmpty {
            return nil
        } else {
            return sections[section]
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchItems.isEmpty {
            return 1
        } else {
            return searchItems[section].count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchItems.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "noAlbumsResultCell", for: indexPath)
        } else {
            let identifier = "artistCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            configureCell(cell: cell, indexPath: indexPath)
            
            return cell
        }
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchItems.isEmpty {
            return CGFloat.leastNormalMagnitude
        } else {
            return 30.0
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchItems.isEmpty {
            return nil
        } else {
            return indexPath
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ArtistDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
