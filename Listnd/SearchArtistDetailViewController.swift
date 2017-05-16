//
//  SearchArtistDetailViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/17/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD
import GSKStretchyHeaderView
import SwiftMessages

// MARK: - Notification key
let albumImageDownloadNotification = "com.RhL.albumImageNotificationKey"

class SearchArtistDetailViewController: UIViewController {
    
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
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: artistImageDownloadNotification), object: nil)
        if isLoading == true {
            SVProgressHUD.dismiss()
        }
    }
}

//MARK: - Helper methods
extension SearchArtistDetailViewController {
    func configureUI() {
        let nib = UINib(nibName: "TableSectionHeader", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "TableSectionHeader")
        if let headerView = Bundle.main.loadNibNamed("HeaderView", owner: self, options: nil)?.first as? HeaderView {
            self.headerView = headerView
            headerView.configureView(name: currentArtist.name, imageData: currentArtist.artistImage as Data?, hideButton: true)
            if currentArtist.artistImage == nil {
                NotificationCenter.default.addObserver(self, selector: #selector(SearchArtistDetailViewController.artistImageDownloaded), name: NSNotification.Name(rawValue: artistImageDownloadNotification), object: nil)
            }
            headerView.backButton.addTarget(self, action: #selector(backButtonPressed(sender:)), for: .touchUpInside)
            tableView.addSubview(headerView)
            registerNib()
            getAlbums(artistId: currentArtist.id)
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "There was an error loading the artist detail")
        }
    }
    
    func registerNib() {
        let albumNib = UINib(nibName: "SearchAlbumCell", bundle: nil)
        tableView.register(albumNib, forCellReuseIdentifier: "albumCell")
        let noResultNib = UINib(nibName: "NoSearchResultCell", bundle: nil)
        tableView.register(noResultNib, forCellReuseIdentifier: "noResultCell")
    }
    
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
                    SwiftMessages.sharedInstance.displayError(title: "Alert", message: errorMessage)
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
extension SearchArtistDetailViewController: UITableViewDataSource {
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
            return tableView.dequeueReusableCell(withIdentifier: "noResultCell", for: indexPath)
        } else {
            let identifier = "albumCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! SearchAlbumCell
            let album = searchItems[indexPath.section][indexPath.row]
            cell.configure(withAlbum: album)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension SearchArtistDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "SearchAlbumDetailViewController") as! SearchAlbumDetailViewController
        
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
            return 24.0
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

// MARK: - UIGestureRecognizerDelegate
extension SearchArtistDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
