//
//  ArtistDetailViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/17/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD
import GSKStretchyHeaderView
import JSSAlertView
import SwipeCellKit

// MARK: - Notification key
let albumImageDownloadNotification = "com.RhL.albumImageNotificationKey"

class ArtistDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var coreDataStack: CoreDataStack!
    var currentArtist: Artist!
    var sections = [String]()
    var searchItems = [[Album]]()
    var albumIndex: Int?
    var singleIndex: Int?
    var selectedRow: IndexPath?
    var isLoading: Bool?
    var headerView: HeaderView!
    var fetchingAlbums = true
    var alertView: JSSAlertView!
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertView = JSSAlertView()
        let nib = UINib(nibName: "TableSectionHeader", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "TableSectionHeader")
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            self.headerView = headerView
            headerView.configureView(name: currentArtist.name, imageData: currentArtist.artistImage as? Data, hideButton: true)
            headerView.imageTemplate.image = UIImage(named: "headerPlaceHolder")
            if currentArtist.artistImage == nil {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(ArtistDetailViewController.artistImageDownloaded),
                                                       name: NSNotification.Name(rawValue: artistImageDownloadNotification),
                                                       object: nil)
            }
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            getAlbums(artistId: currentArtist.id)
        } else {
            alertView.danger(self, title: "There was an error loading the artist detail", text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
            
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
                    SVProgressHUD.dismiss()
                    
                    self.alertView.danger(self, title: errorMessage, text: nil, buttonText: nil, cancelButtonText: nil, delay: nil, timeLeft: nil)
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
        
        cell.delegate = self
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
            headerView.setImage(data: imageData as Data)
        }
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TableSectionHeader") as! TableSectionHeader
        var title: String?
        
        if !searchItems.isEmpty {
            title = sections[section]
        }
        
        header.titleLabel.text = title != nil ? title! : ""

        return header
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
        
        albumDetailVC.coreDataStack = coreDataStack
        albumDetailVC.currentAlbum = searchItems[indexPath.section][indexPath.row]
        selectedRow = indexPath
        navigationController?.pushViewController(albumDetailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if searchItems.isEmpty {
            return CGFloat.leastNormalMagnitude
        } else {
            return 28.0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchItems.isEmpty {
            return nil
        } else {
            return indexPath
        }
    }
}

// MARK: - SwipeTableViewCellDelegate
extension ArtistDetailViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction] {
        guard orientation == .right else { return [] }
        let save = SwipeAction(style: .default, title: "Save") { (action, indexPath) in
            print("Saving album")
        }
        
        save.backgroundColor = UIColor.blue
        
        return [save]
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ArtistDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
