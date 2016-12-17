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

let artistImageDownloadNotification = "com.RhL.artistImageNotificationKey"

class SearchViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var artists = [Artist]()
    var tap: UITapGestureRecognizer!
    var isSearching: Bool?
    var hasSearched = false
    var selectedRow: IndexPath?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .normal)
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        searchBar.delegate = self
    }
}

// MARK: - Helper methods
extension SearchViewController {
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? SearchTableViewCell else { return }
        
        cell.searchImageVIew.image = UIImage(named: "thumbnailPlaceHolder")
        cell.layoutSubviews()
        let artist = artists[indexPath.row]
        cell.searchLabel.text = artist.name
        
        if let data = artist.artistImage {
            let image = UIImage(data: data as Data)
            cell.searchImageVIew?.image = image
        } else {
            getAlbumImage(url: artist.imageURL, completetionHandlerForAlbumImage: { (data) in
                artist.artistImage = NSData(data: data as Data)
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: cell.searchImageVIew, duration: 1, options: .transitionCrossDissolve, animations: { cell.searchImageVIew.image = image }, completion: nil)
                    cell.layoutSubviews()
                    if self.selectedRow == indexPath {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: artistImageDownloadNotification), object: self)
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
        searchBar.resignFirstResponder()
        enableCancelButton(searchBar: searchBar)
        deleteObjects()
        isSearching = true
        hasSearched = true
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Loading...")
        SpotifyAPI.sharedInstance.searchArtist(searchBar.text!) { (success, results, errorMessage) in
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                if success {
                    if let searchResults = results {
                        self.artists = searchResults
                        self.tableView.reloadData()
                    } else {
                        SwiftMessages.sharedInstance.displayError(title: "Alert", message: errorMessage)
                    }
                    self.isSearching = false
                } else {
                    SwiftMessages.sharedInstance.displayError(title: "Alert", message: errorMessage)
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if isSearching == true {
            SpotifyAPI.sharedInstance.cancelRequest()
        }
        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        deleteObjects()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
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
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !hasSearched {
            return 0
        } else if artists.isEmpty {
            return 1
        } else {
            return artists.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if artists.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "noResultCell", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
            configureCell(cell: cell, indexPath: indexPath)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "ArtistDetailViewController") as! ArtistDetailViewController
        
        let artist = artists[indexPath.row]
        selectedRow = indexPath
        detailVC.currentArtist = artist
        navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if artists.count == 0 {
            return nil
        } else {
            return indexPath
        }
    }
}

extension SVProgressHUD {
    func visibleKeyboardHeight() -> CFloat {
        return 0.0
    }
}
