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
import SwiftMessages

// MARK: - Notification key
let artistImageDownloadNotification = "com.RhL.artistImageNotificationKey"

class SearchViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var coreDataStack: CoreDataStack!
    var searchResults = [AnyObject]()
    var filteredResult = [AnyObject]()
    var artists = [Artist]()
    var albums = [Album]()
    var tracks = [Track]()
    var tap: UITapGestureRecognizer!
    var isSearching: Bool?
    var hasSearched = false
    var selectedRow: IndexPath?
    var isFiltered = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
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
        let albumNib = UINib(nibName: "SearchAlbumCell", bundle: nil)
        tableView.register(albumNib, forCellReuseIdentifier: "albumCell")
        let songNib = UINib(nibName: "SearchSongCell", bundle: nil)
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
    
    func filterSearch(forIndex index: Int) {
        isFiltered = true
        switch index {
        case 0: isFiltered = false
        filteredResult.removeAll()
        tableView.reloadData()
        case 1: filteredResult.removeAll()
        for item in searchResults {
            if let _ = item as? Album {
                filteredResult.append(item)
            }
        }
        tableView.reloadData()
        case 2: filteredResult.removeAll()
        for item in searchResults {
            if let _ = item as? Artist {
                filteredResult.append(item)
            }
        }
        tableView.reloadData()
        case 3: filteredResult.removeAll()
        for item in searchResults {
            if let _ = item as? Track {
                filteredResult.append(item)
            }
        }
        tableView.reloadData()
        default: break
        }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: UITableViewScrollPosition.top, animated: false)
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
                    if let results = results {
                        self.searchResults.removeAll()
                        DispatchQueue.main.async {
                            self.searchResults = results
                            if self.isFiltered {
                                self.filterSearch(forIndex: self.searchBar.selectedScopeButtonIndex)
                            }
                            self.tableView.reloadData()
                        }
                    } else {
                        print(errorMessage)
                    }
                }
            })
        } else {
            SwiftMessages.sharedInstance.displayError(title: "Alert", message: "Unable to search\nNo internet connection detected")
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
        filterSearch(forIndex: selectedScope)
    }
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if hasSearched == false {
            return 0
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hasSearched {
            return 0
        } else if searchResults.isEmpty || (isFiltered && filteredResult.isEmpty) {
            return 1
        } else {
            if isFiltered {
                return filteredResult.count
            } else {
                return searchResults.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchResults.isEmpty || (isFiltered && filteredResult.isEmpty) {
            return tableView.dequeueReusableCell(withIdentifier: "noResultCell", for: indexPath)
        } else {
            
            let selectedItem = isFiltered ? filteredResult[indexPath.row] : searchResults[indexPath.row]
            
            if selectedItem is Artist {
                let cell = tableView.dequeueReusableCell(withIdentifier: "artistCell", for: indexPath) as! SearchArtistCell
                cell.configure(withArtist: selectedItem)
                return cell
            } else if selectedItem is Album {
                let cell = tableView.dequeueReusableCell(withIdentifier: "albumCell", for: indexPath) as! SearchAlbumCell
                cell.configure(withAlbum: selectedItem)
                return cell
            } else if selectedItem is Track {
                let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SearchSongCell
                cell.configure(withTrack: selectedItem)
                return cell
            }
        }
        
        return tableView.dequeueReusableCell(withIdentifier: "noResultCell", for: indexPath)
    }
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedItem = isFiltered ? filteredResult[indexPath.row] : searchResults[indexPath.row]
        
        if selectedItem is Artist {
            let artist = selectedItem as! Artist
            let detailVC = storyboard?.instantiateViewController(withIdentifier: "ArtistDetailViewController") as! ArtistDetailViewController
            selectedRow = indexPath
            detailVC.coreDataStack = coreDataStack
            detailVC.currentArtist = artist
            navigationController?.pushViewController(detailVC, animated: true)
        } else if selectedItem is Album {
            let album = selectedItem as! Album
            let detailVC = storyboard?.instantiateViewController(withIdentifier: "AlbumDetailViewController") as! AlbumDetailViewController
            selectedRow = indexPath
            detailVC.coreDataStack = coreDataStack
            detailVC.currentAlbum = album
            detailVC.albumId = album.id
            navigationController?.pushViewController(detailVC, animated: true)
        } else if selectedItem is Track {
            let song = selectedItem as! Track
            let detailVC = storyboard?.instantiateViewController(withIdentifier: "AlbumDetailViewController") as! AlbumDetailViewController
            selectedRow = indexPath
            detailVC.coreDataStack = coreDataStack
            detailVC.albumId = song.album?.id
            navigationController?.pushViewController(detailVC, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.isEmpty {
            return nil
        } else {
            return indexPath
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
