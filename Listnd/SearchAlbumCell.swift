//
//  SearchAlbumCell.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/25/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class SearchAlbumCell: UITableViewCell {
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumArtistLabel: UILabel!
    @IBOutlet weak var albumDetailLabel: UILabel!
    
    var cell = SearchAlbumCell.self {
        didSet {
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        albumImageView.layer.cornerRadius = 6.5
        albumImageView.clipsToBounds = true
    }
    
    func configure(withAlbum item: AnyObject) {
        let album = item as! Album
        
        self.albumImageView.image = UIImage(named: "thumbnailPlaceHolder")
        
        self.albumNameLabel.text = album.name
        self.albumArtistLabel.text = album.artist!.name
        self.albumDetailLabel.text = String(album.type.characters.prefix(1)).uppercased() + String(album.type.characters.dropFirst())
        
        if let data = album.artworkImage {
            let image = UIImage(data: data as Data)
            self.albumImageView.image = image
        } else {
            getAlbumImage(url: album.artworkUrl, completetionHandlerForAlbumImage: { (data) in
                album.artworkImage = NSData(data: data as Data)
                DispatchQueue.main.async {
                    let image = UIImage(data: data as Data)
                    UIView.transition(with: self.albumImageView, duration: 1, options: .transitionCrossDissolve, animations: { self.albumImageView.image = image }, completion: nil)
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
