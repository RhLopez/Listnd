//
//  SearchArtistCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/30/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class SearchArtistCell: UITableViewCell {
    
    @IBOutlet weak var artistImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artistDetailLabel: UILabel!
    
    var cell = SearchArtistCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        artistImageView.layer.cornerRadius = 6.5
        artistImageView.clipsToBounds = true
    }
    
    func configure(withArtist item: AnyObject) {
        let artist = item as! Artist
        self.artistImageView.image = UIImage(named: "thumbnailPlaceHolder")

        self.artistNameLabel.text = artist.name
        self.artistDetailLabel.text = "Artist"
        
        if let data = artist.image {
            let image = UIImage(data: data as Data)
            self.artistImageView?.image = image
        } else {
            getAlbumImage(url: artist.imageURL, completetionHandlerForAlbumImage: { (data) in
                artist.image = NSData(data: data as Data)
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: self.artistImageView, duration: 1, options: .transitionCrossDissolve, animations: { self.artistImageView.image = image }, completion: nil)
                    // Post notification if cell was selected before image was downloaded
//                    if self.selectedRow == indexPath {
//                        NotificationCenter.default.post(name: Notification.Name(rawValue: artistImageDownloadNotification), object: self)
//                    }
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
