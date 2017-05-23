//
//  ArtistCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/25/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class ArtistCell: UITableViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var albumCountLabel: UILabel!
    
    var cell = ArtistCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        artistImageView.layer.cornerRadius = 6.5
        artistImageView.clipsToBounds = true
    }
    
    func configure(with artist: Artist) {
        self.nameLabel.text = artist.name
        self.artistImageView.image = UIImage(named: "headerPlaceHolder")
        
        var albumCountMessage = ""
        if let count = artist.albums?.count {
            if count > 0 {
                albumCountMessage = count > 1 ? "\(count) Albums" : "\(count) Album"
            } else {
                albumCountMessage = "No Albums"
            }
        } else {
            albumCountMessage = ""
        }
        self.albumCountLabel.text = albumCountMessage
        
        if artist.listened {
            self.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            self.accessoryType = UITableViewCellAccessoryType.none
        }
        
        // Get album image if the album was saved prior to image being saved due to slow connetcion
        if let data = artist.artistImage {
            print("setting: \(artist.name)")
            self.artistImageView.image = UIImage(data: data as Data)
        } else {
            getAlbumImage(url: artist.imageURL, completetionHandlerForAlbumImage: { (data) in
                artist.artistImage = data
                let image = UIImage(data: data as Data)
                DispatchQueue.main.async {
                    UIView.transition(with: self.artistImageView, duration: 1, options: .transitionCrossDissolve, animations: { self.artistImageView.image = image }, completion: nil)
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
}
