//
//  Track.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 5/22/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import  RealmSwift

class Track: Object {
    dynamic var name: String = ""
    dynamic var id: String = ""
    dynamic var uri: String = ""
    dynamic var duration: Int = 0
    dynamic var previewUrl: String? = nil
    dynamic var listened: Bool = false
    dynamic var trackNumber: Int = 0
    dynamic var album: Album? = nil
    
    convenience init?(json: [String: AnyObject]) {
        guard let name = json["name"] as? String,
            let id = json["id"] as? String,
            let trackNumber = json["track_number"] as? Int,
            let uri = json["uri"] as? String,
            let duration = json["duration_ms"] as? Int else { return nil }
        
        self.init()
        self.name = name
        self.id = id
        self.trackNumber = trackNumber
        self.uri = uri
        self.duration = duration
        
        if let albumInfo = json["album"] as? [String: AnyObject] {
            self.album = Album(json: albumInfo)
        }
        
        if let url = json["preview_url"] as? String {
            self.previewUrl = url
        }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
