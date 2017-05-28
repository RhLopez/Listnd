//
//  Album.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 5/22/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import RealmSwift

class Album: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var type: String = ""
    dynamic var uri: String = ""
    dynamic var artworkUrl: String? = nil
    dynamic var artworkImage: NSData? = nil
    dynamic var listened: Bool = false
    dynamic var artist: Artist? = nil
    dynamic var listenedCount: Int = 0
    
    var tracks = List<Track>()
    
    convenience init?(json: [String: AnyObject]) {
        guard let name = json["name"] as? String,
            let id = json["id"] as? String,
            let uri = json["uri"] as? String,
            let type = json["album_type"] as? String,
            let images = json["images"] as? [[String: AnyObject]],
            let artistInfo = json["artists"] as? [[String: AnyObject]] else { return nil }
        
        let artist = artistInfo.flatMap { Artist(json: $0) }
        
        self.init()
        self.name = name
        self.id = id
        self.uri = uri
        self.type = type
        self.artist = artist.first
        self.artworkUrl = parseImageUrl(json: images)
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

// MARK: Image URL Parser
extension Album {
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
