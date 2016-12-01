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

let albumImageDownloadNotification = "com.RhL.albumImageNotificationKey"

class ArtistDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet var headerView: GSKStretchyHeaderView!
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
    var isLoading: Bool?
    
    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addSubview(headerView)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
        setUpUI()
        getAlbums(artistId: currentArtist.id)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        artistImageView.layer.cornerRadius = 6.5
        artistImageView.clipsToBounds = true
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
    func setUpUI() {
        artistNameLabel.text = currentArtist.name
        artistImageView.image = UIImage(named: "coverImagePlaceHolder")
        if let imageData = currentArtist.artistImage {
            setArtistImage(imageData: imageData)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(ArtistDetailViewController.artistImageDownloaded), name: NSNotification.Name(rawValue: artistImageDownloadNotification), object: nil)
        }
        backgroundImageView.image = UIImage(named: "backgroundImage")
    }
    
    func getAlbums(artistId: String) {
        isLoading = true
        SVProgressHUD.setDefaultStyle(.dark)
        SVProgressHUD.show(withStatus: "Loading...")
        SpotifyAPI.sharedInstance.getAlbums(artistId) { (results, errorMessage) in
            if let searchResults = results {
                self.processAlbumSections(albums: searchResults)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    self.tableView.reloadData()
                    self.isLoading = false
                }
            } else {
                let messageView = MessageView.viewFromNib(layout: .TabView)
                messageView.configureTheme(.error)
                messageView.configureContent(title: "Error", body: errorMessage)
                SwiftMessages.show(view: messageView)
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
                if searchItems.isEmpty {
                    searchItems.append([album])
                } else {
                    searchItems[albumIndex!].append(album)
                }
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, indexPath: IndexPath) {
        guard let cell = cell as? ArtistDetailTableViewCell else { return }
        
        cell.albumImageView.image = UIImage(named: "placeHolder")
        
        let album = searchItems[indexPath.section][indexPath.row]
        cell.albumNameLabel.text = album.name
        
        if let data = album.albumImage {
            let image = UIImage(data: data as Data)
            UIView.transition(with: cell.albumImageView, duration: 1, options: .transitionCrossDissolve, animations: { cell.albumImageView.image = image }, completion: nil)
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
            let image = UIImage(named: "coverImagePlaceHolder")
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30.0
    }
}

//extension ArtistDetailViewController: UIScrollViewDelegate {
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        let offset_HeaderStop: CGFloat = 1.0
//        let offset = scrollView.contentOffset.y
//        var imageTransform = CATransform3DIdentity
//        
//        let avatarScaleFactor = (min(offset_HeaderStop, offset)) / artistImageView.bounds.height // Slow down the animation
//        let avatarSizeVariation = ((artistImageView.bounds.height * (1.0 + avatarScaleFactor)) - artistImageView.bounds.height) / 2.0
//        imageTransform = CATransform3DTranslate(imageTransform, 0, avatarSizeVariation, 0)
//        imageTransform = CATransform3DScale(imageTransform, 1.0 - avatarScaleFactor, 1.0 - avatarScaleFactor, 0)
//        
//        if offset <= offset_HeaderStop {
//            
//            if artistImageView.layer.zPosition < headerView.layer.zPosition{
//                headerView.layer.zPosition = 0
//            }
//            
//        }else {
//            if artistImageView.layer.zPosition >= headerView.layer.zPosition{
//                headerView.layer.zPosition = 2
//            }
//        }
//        
//        artistImageView.layer.transform = imageTransform
//    }
//}

// MARK: - UIGestureRecognizerDelegate
extension ArtistDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
