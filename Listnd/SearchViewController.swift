//
//  SearchViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

class SearchViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var artists = [Artist]()
    var tap: UITapGestureRecognizer!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .normal)
        tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        searchBar.delegate = self
        searchBar.backgroundImage = UIImage()
    }
}

// MARK: - Helper methods
extension SearchViewController {
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? SearchTableViewCell else { return }
        
        let viewBackground = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        viewBackground.backgroundColor = UIColor(red: 148/255, green: 179/255, blue: 252/255, alpha: 1.0)
        cell.selectedBackgroundView = viewBackground
        cell.activityIndicator.startAnimating()
        cell.searchImageVIew.image = UIImage(named: "placeHolder")
        cell.layoutSubviews()
        let artist = artists[indexPath.row]
        cell.searchLabel.text = artist.name
        
        if artist.artistImage == nil {
            if artist.imageURL == "" {
                let image = UIImage(named: "noImage")
                let imageData = UIImagePNGRepresentation(image!)!
                artist.artistImage = NSData(data: imageData)
                DispatchQueue.main.async {
                    cell.searchImageVIew.image = image
                    cell.layoutSubviews()
                    cell.activityIndicator.stopAnimating()
                }
            } else {
                SpotifyAPI.sharedInstance.getImage(artist.imageURL!) { (data) in
                    if let resultData = data {
                        artist.artistImage = NSData(data: resultData)
                        let image = UIImage(data: resultData)
                        DispatchQueue.main.async {
                            cell.searchImageVIew?.image = image
                            cell.layoutSubviews()
                            cell.activityIndicator.stopAnimating()
                        }
                    }
                }
            }
        } else {
            let image = UIImage(data: artist.artistImage as! Data)
            cell.searchImageVIew?.image = image
            cell.activityIndicator.stopAnimating()
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
        SpotifyAPI.sharedInstance.searchArtist(searchBar.text!) { (success, results, errorMessage) in
            if success {
                if let searchResults = results {
                    self.artists = searchResults
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } else {
                print(errorMessage ?? "")
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.resignFirstResponder()
        deleteObjects()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            searchBar.becomeFirstResponder()
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        view.addGestureRecognizer(tap)
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        view.removeGestureRecognizer(tap)
        return true
    }
}

// MARK: - UITableViewDataSource
extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "searchCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailVC = storyboard?.instantiateViewController(withIdentifier: "ArtistDetailCollectionViewController") as! ArtistCollectionViewController
        
        detailVC.currentArtist = artists[indexPath.row]
        navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
