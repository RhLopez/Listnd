//
//  ArtistDetailCollectionViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/8/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

class ArtistCollectionViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var artistCoverImage: UIImageView!
    @IBOutlet weak var artistBackgroundImage: UIImageView!
    @IBOutlet weak var artistCoverNameLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - Properties
    var stack = CoreDataStack.sharedInstance
    var currentArtist: Artist?
    var albums = [Album]()

    // MARK: - Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 7, 1)
        if let artist = currentArtist {
            artistCoverNameLabel.text = artist.name
            artistCoverNameLabel.sizeToFit()
            let artistImage = UIImage(data: artist.artistImage as! Data)
            artistCoverImage.image = artistImage
            artistBackgroundImage.image = UIImage(named: "backgroundImage")
            getAlbums(artistId: artist.id!)
            getCellSize()
        } else {
            print("Unable to get albums")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        artistCoverImage.layer.cornerRadius = 6.5
        artistCoverImage.clipsToBounds = true
    }
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    
} 
// MARK: - Helper Method
extension ArtistCollectionViewController {
    func getCellSize() {
        let space: CGFloat = 1.0
        let dimension = (view.bounds.width - (2 * space)) / 2
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func getAlbums(artistId: String) {
        SpotifyAPI.sharedInstance.getAlbums(artistId) { (success, results, errorMessage) in
            if success {
                if let searchResults = results {
                    for album in searchResults {
                        album.artist = self.currentArtist!
                    }
                    self.albums = searchResults
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            } else {
                print(errorMessage ?? "")
            }
        }
    }
    
    func confirgureCell(cell: UICollectionViewCell, indexPath: IndexPath) {
        guard let cell = cell as? ArtistDetailCollectionViewCell else { return }
        
        cell.activityIndicatior.startAnimating()
        cell.albumImageView.image = UIImage(named: "placeHolder")
        
        let album = albums[indexPath.row]
        cell.albumNameLabel.text = album.name
        
        if album.albumImage == nil {
            if album.imageURL == "" {
                let image = UIImage(named: "noImage")
                let imageData = UIImagePNGRepresentation(image!)
                album.albumImage = NSData(data: imageData!)
                DispatchQueue.main.async {
                    cell.albumImageView.image = image
                    cell.activityIndicatior.stopAnimating()
                }
            } else {
                SpotifyAPI.sharedInstance.getImage(album.imageURL, completionHandlerForImage: { (data) in
                    if let resultData = data {
                        album.albumImage = NSData(data: resultData)
                        let image = UIImage(data: resultData)
                        DispatchQueue.main.async {
                            cell.albumImageView.image = image
                            cell.activityIndicatior.stopAnimating()
                        }
                    }
                })
            }
        } else {
            let image = UIImage(data: album.albumImage as! Data)
            cell.albumImageView.image = image
            cell.activityIndicatior.stopAnimating()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ArtistCollectionViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UICollectionViewDataSource
extension ArtistCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albums.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifer = "albumCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifer, for: indexPath)
        confirgureCell(cell: cell, indexPath: indexPath)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ArtistCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let albumDetailVC = storyboard?.instantiateViewController(withIdentifier: "AlbumDetailViewController") as! AlbumDetailViewController
        
        albumDetailVC.currentAlbum = albums[indexPath.row]
        navigationController?.pushViewController(albumDetailVC, animated: true)
    }
}
