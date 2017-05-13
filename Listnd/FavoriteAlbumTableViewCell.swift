//
//  FavoriteAlbumTableViewCell.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/16/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class FavoriteAlbumTableViewCell: UITableViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumDetailLabel: UILabel!
    
    var cell = FavoriteAlbumTableViewCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        albumImageView.layer.cornerRadius = 6.5
        albumImageView.clipsToBounds = true
    }
    
    func configure(with album: Album) {
        self.albumNameLabel.text = album.name
        self.albumImageView.image = UIImage(named: "headerPlaceHolder")
        
        if let data = album.albumImage {
            self.albumImageView.image = UIImage(data: data as Data)
        } else {
            // Get album image if the album was saved prior to image being saved due to slow connetcion
            getAlbumImage(url: album.imageURL, completetionHandlerForAlbumImage: { (data) in
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: self.albumImageView, duration: 1, options: .transitionCrossDissolve, animations: { self.albumImageView.image = image }, completion: nil)
                    album.albumImage = data
                }
            })
        }
        
        self.albumDetailLabel.text = "\(album.listenedCount) of \(album.tracks!.count) Tracks Lisntd"
        
        if album.listened {
            self.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            self.accessoryType = UITableViewCellAccessoryType.none
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
}
