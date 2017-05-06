//
//  SearchViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData
import SVProgressHUD

// MARK: - Notification key
let artistImageDownloadNotification = "com.RhL.artistImageNotificationKey"

class SearchViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var coreDataStack: CoreDataStack!
    var searchResults = [[AnyObject]]()
    var filteredResult = [AnyObject]()
    var artists = [Artist]()
    var albums = [Album]()
    var tracks = [Track]()
    var tap: UITapGestureRecognizer!
    var isSearching: Bool?
    var hasSearched = false
    var selectedRow: IndexPath?
    var alertView: JSSAlertView!
    var isFiltered = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        alertView = JSSAlertView()
        setupUI()
    }
    
    func setupUI() {
        // Change searchBar Cancel button font color to white
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .normal)
        registerNibs()
        setupSearchBar()
    }
    
    func registerNibs() {
        let artistNib = UINib(nibName: "SearchArtistCell", bundle: nil)
        tableView.register(artistNib, forCellReuseIdentifier: "artistCell")
        let albumNib = UINib(nibName: "AlbumCell", bundle: nil)
        tableView.register(albumNib, forCellReuseIdentifier: "albumCell")
        let songNib = UINib(nibName: "SongCell", bundle: nil)
        tableView.register(songNib, forCellReuseIdentifier: "songCell")
        let noResultNib = UINib(nibName: "NoSearchResultCell", bundle: nil)
        tableView.register(noResultNib, forCellReuseIdentifier: "noResultCell")
        let nib = UINib(nibName: "TableSectionHeader", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "TableSectionHeader")
    }
    
    func setupSearchBar() {
        searchBar.delegate = self
        searchBar.setScopeBarButtonTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .normal)
        searchBar.scopeButtonTitles = ["All", "Album", "Artist", "Song"]
        searchBar.selectedScopeButtonIndex = 0
    }
}

// MARK: - Helper methods
extension SearchViewController {
    func configureArtistCell(_ cell: UITableViewCell, forIndextPath indexPath: IndexPath) {
        guard let cell = cell as? SearchArtistCell else { return }
        
        cell.artistImageView.image = UIImage(named: "thumbnailPlaceHolder")
        let artist = artists[indexPath.row]
        cell.artistNameLabel.text = artist.name
 
        if let data = artist.artistImage {
            let image = UIImage(data: data as Data)
            cell.artistImageView?.image = image
        } else {
            getAlbumImage(url: artist.imageURL, completetionHandlerForAlbumImage: { (data) in
                artist.artistImage = NSData(data: data as Data)
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: cell.artistImageView, duration: 1, options: .transitionCrossDissolve, animations: { cell.artistImageView.image = image }, completion: nil)
                    // Post notification if cell was selected before image was downloaded
                    if self.selectedRow == indexPath {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: artistImageDownloadNotification), object: self)
                    }
                }
            })
        }
    }
    
    func configureAlbumCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath) {
        guard let cell = cell as? AlbumCell else { return }
        
        cell.albumImageView.image = UIImage(named: "thumbnailPlaceHolder")
        let album = albums[indexPath.row]
        cell.albumNameLabel.text = album.name
        cell.albumDetailLabel.text = album.artistString
        
        if let data = album.albumImage {
            let image = UIImage(data: data as Data)
            cell.albumImageView.image = image
        } else {
            getAlbumImage(url: album.imageURL, completetionHandlerForAlbumImage: { (data) in
                album.albumImage = NSData(data: data as Data)
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: cell.albumImageView, duration: 1, options: .transitionCrossDissolve, animations: { cell.albumImageView.image = image }, completion: nil)
                }
            })
        }
    }
    
    func configureSongCell(_ cell: UITableViewCell, forIndexPath indexPath: IndexPath) {
        guard let cell = cell as? SongCell else { return }
        
        let song = tracks[indexPath.row]
        cell.songNameLabel.text = song.name
        cell.songDetailLabel.text = "\(song.artistString) • \(song.albumNameString)"
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
    
    func deleteObjects() {
        artists.removeAll()
        albums.removeAll()
        tracks.removeAll()
        searchResults.removeAll()
        hasSearched = false
        tableView.reloadData()
    }
    
    func dismissKeyboard() {
        searchBar.endEditing(true)
        searchBar.resignFirstResponder()
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if Reachability.sharedInstance.isConnectedToNetwork() == true {
            searchBar.showsScopeBar = true
            searchBar.resignFirstResponder()
            enableCancelButton(searchBar: searchBar)
            isSearching = true
            hasSearched = true
            SVProgressHUD.setDefaultStyle(.dark)
            SVProgressHUD.show(withStatus: "Loading...")
            SpotifyAPI.sharedInstance.search(searchBar.text!, completionHanderForSearch: { (success, results, errorMessage) in
                DispatchQueue.main.async {
                    self.isSearching = false
                    SVProgressHUD.dismiss()
                    if success {
                        self.searchResults.removeAll()
                        for item in results! {
                            if let albumArray = item as? Array<Album> {
                                self.albums = albumArray
                                self.searchResults.append(self.albums)
                            } else if let artistArray = item as? Array<Artist> {
                                self.artists = artistArray
                                self.searchResults.append(self.artists)
                            } else if let trackArray = item as? Array<Track> {
                                self.tracks = trackArray
                                self.searchResults.append(self.tracks)
                            }
                        }
                        self.tableView.reloadData()
                    } else {
                        print(errorMessage)
                    }
                }
            })
        } else {
            alertView.danger(self, title: "Unable to search.\nNo internet connection detected", text: nil, buttonText: "Ok", cancelButtonText: nil, delay: nil, timeLeft: nil)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if isSearching == true {
            SpotifyAPI.sharedInstance.cancelRequest()
        }
        searchBar.text = nil
        searchBar.resignFirstResponder()
        searchBar.showsScopeBar = false
        deleteObjects()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            searchBar.showsScopeBar = false
            deleteObjects()
            searchBar.becomeFirstResponder()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        view.addGestureRecognizer(tap)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        view.removeGestureRecognizer(tap)
        return true
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        isFiltered = true
        switch selectedScope {
        case 0: isFiltered = false
            filteredResult.removeAll()
            tableView.reloadData()
        case 1: filteredResult.removeAll()
            filteredResult = albums
            tableView.reloadData()
        case 2: filteredResult.removeAll()
            filteredResult = artists
            tableView.reloadData()
        case 3: filteredResult.removeAll()
            filteredResult = tracks
            tableView.reloadData()
        default: break
        }
    }
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if hasSearched == false {
            return 0
        } else if artists.isEmpty && albums.isEmpty && tracks.isEmpty || isFiltered {
            return 1
        } else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hasSearched {
            return 0
        } else if artists.isEmpty && albums.isEmpty && tracks.isEmpty || (isFiltered && filteredResult.isEmpty) {
            return 1
        } else {
            if isFiltered {
                return filteredResult.count
            } else {
                return searchResults[section].count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchResults[indexPath.section].isEmpty || (isFiltered && filteredResult.isEmpty) {
            return tableView.dequeueReusableCell(withIdentifier: "noResultCell", for: indexPath)
        } else {
            var identifer = ""
            if isFiltered {
                switch searchBar.selectedScopeButtonIndex {
                case 0: break
                case 1: identifer = "albumCell"
                case 2: identifer = "artistCell"
                case 3: identifer = "songCell"
                default: break
                }
            } else {
                switch indexPath.section {
                case 0: identifer = "albumCell"
                case 1: identifer = "artistCell"
                case 2: identifer = "songCell"
                default: break
                }
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath)
            
            if isFiltered {
                switch searchBar.selectedScopeButtonIndex {
                case 0: break
                case 1: configureAlbumCell(cell, forIndexPath: indexPath)
                case 2: configureArtistCell(cell, forIndextPath: indexPath)
                case 3: configureSongCell(cell, forIndexPath: indexPath)
                default: break
                }
            } else {
                switch indexPath.section {
                case 0: configureAlbumCell(cell, forIndexPath: indexPath)
                case 1: configureArtistCell(cell, forIndextPath: indexPath)
                case 2: configureSongCell(cell, forIndexPath: indexPath)
                default: break
                }
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TableSectionHeader") as! TableSectionHeader
        if isFiltered { return nil }
        var title = ""
        
        switch section {
        case 0: title = "Albums"
        case 1: title = "Artists"
        case 2: title = "Songs"
        default: break
        }
        
        header.titleLabel.text = title
        
        return header
    }
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var selectedCell = 0
        
        if isFiltered {
            selectedCell = searchBar.selectedScopeButtonIndex
        } else {
            selectedCell = indexPath.section + 1 // Add one to match searchBar scope button indexes
        }
        
        switch selectedCell {
        case 0: break
        case 1: let detailVC = storyboard?.instantiateViewController(withIdentifier: "AlbumDetailViewController") as! AlbumDetailViewController
            let album = albums[indexPath.row]
            selectedRow = indexPath
            detailVC.coreDataStack = coreDataStack
            detailVC.currentAlbum = album
            navigationController?.pushViewController(detailVC, animated: true)
        case 2: let detailVC = storyboard?.instantiateViewController(withIdentifier: "ArtistDetailViewController") as! ArtistDetailViewController
            let artist = artists[indexPath.row]
            selectedRow = indexPath
            detailVC.coreDataStack = coreDataStack
            detailVC.currentArtist = artist
            navigationController?.pushViewController(detailVC, animated: true)
        case 3: let detailVC = storyboard?.instantiateViewController(withIdentifier: "AlbumDetailViewController") as! AlbumDetailViewController
            let song = tracks[indexPath.row]
            selectedRow = indexPath
            detailVC.coreDataStack = coreDataStack
            detailVC.albumId = song.albumId
            navigationController?.pushViewController(detailVC, animated: true)
        default: break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults[indexPath.section].isEmpty {
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isFiltered || searchResults[section].isEmpty {
            return CGFloat.leastNormalMagnitude
        } else {
            return 24.0
        }
    }
}

// MARK: - SVProgressHUD
extension SVProgressHUD {
    // Adjust position of progess hud after keyboard is dismissed
    func visibleKeyboardHeight() -> CFloat {
        return 0.0
    }
}
