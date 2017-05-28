//
//  Artist.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 5/22/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import RealmSwift

class Artist: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var imageURL: String? = nil
    dynamic var image: NSData? = nil
    dynamic var listened: Bool = false
    
    let albums = List<Album>()
    
    convenience init?(json: [String: AnyObject]) {
        guard let name = json["name"] as? String,
            let id = json["id"] as? String else { return nil }
        
        self.init()
        self.name = name
        self.id = id
        
        if let images = json["images"] as? [[String: AnyObject]] {
            imageURL = parseImageUrl(json: images)
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

// MARK: - Image URL Parser
extension Artist {
    func parseImageUrl(json: [[String: AnyObject]]) -> String? {
        if json.isEmpty {
            return nil
        }
        
        let item = json.first!
        guard let url = item["url"] as? String else {
            return nil
        }
        
        return url
    }
}

// MARK: - Artists albums sections
extension Artist {
    var albumTypes: [String] {
        let albumTypes = albums.map { $0.type }
        return Array(Set(albumTypes))
    }
    
    var sectionedAlbum: [[Album]] {
        return albumTypes.map { albumType in
            return albums.filter { $0.type == albumType }
        }
    }
}
