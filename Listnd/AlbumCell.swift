//
//  AlbumCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 5/15/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class AlbumCell: UITableViewCell {
    
    @IBOutlet weak var artworkImageVIew: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumDetailLabel: UILabel!
    
    var cell = AlbumCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        artworkImageVIew.layer.cornerRadius = 6.5
        artworkImageVIew.clipsToBounds = true
    }
    
    func configure(with album: Album) {
        self.albumNameLabel.text = album.name
        self.artworkImageVIew.image = UIImage(named: "headerPlaceHolder")
        
        if let data = album.albumImage {
            self.artworkImageVIew.image = UIImage(data: data as Data)
        } else {
            // Get album image if the album was saved prior to image being saved due to slow connetcion
            getAlbumImage(url: album.imageURL, completetionHandlerForAlbumImage: { (data) in
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: self.artworkImageVIew, duration: 1, options: .transitionCrossDissolve, animations: { self.artworkImageVIew.image = image }, completion: nil)
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
