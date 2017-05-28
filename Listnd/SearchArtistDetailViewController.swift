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
    var currentArtist: Artist!
    var selectedRow: IndexPath?
    var isLoading: Bool?
    var headerView: HeaderView!
    var fetchingAlbums = true
    var sections: [[Album]] = [[]]
    
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
            headerView.configureView(name: currentArtist.name, imageData: currentArtist.image as Data?, hideButton: true)
            if currentArtist.image == nil {
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
                for album in searchResults {
                    self.currentArtist.albums.append(album)
                }
                DispatchQueue.main.async {
                    self.sections = self.currentArtist.sectionedAlbum
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
    
    func artistImageDownloaded() {
        if let imageData = currentArtist.image {
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
        } else if sections.isEmpty {
            return 1
        } else {
            return sections.count
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TableSectionHeader") as! TableSectionHeader
        var title: String?
        
        if !sections.isEmpty {
            let sectionTitle = currentArtist.albumTypes[section]
            title = String(sectionTitle.characters.prefix(1)).uppercased() + String(sectionTitle.characters.dropFirst())
        }
        
        header.titleLabel.text = title != nil ? title! : ""

        return header
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sections.isEmpty {
            return 1
        } else {
            return sections[section].count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if sections.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "noResultCell", for: indexPath)
        } else {
            let identifier = "albumCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! SearchAlbumCell
            let album = sections[indexPath.section][indexPath.row]
            cell.configure(withAlbum: album)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension SearchArtistDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "SearchAlbumDetailViewController") as! SearchAlbumDetailViewController
        
        albumDetailVC.currentAlbum = sections[indexPath.section][indexPath.row]
        selectedRow = indexPath
        navigationController?.pushViewController(albumDetailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections.isEmpty {
            return CGFloat.leastNormalMagnitude
        } else {
            return 24.0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if sections.isEmpty {
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
