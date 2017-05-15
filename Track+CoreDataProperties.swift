//
//  Track+CoreDataProperties.swift
//  
//
//  Created by Ramiro H Lopez on 4/30/17.
//
//

import Foundation
import CoreData


extension Track {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Track> {
        return NSFetchRequest<Track>(entityName: "Track")
    }

    @NSManaged public var artistString: String?
    @NSManaged public var duration: Int32
    @NSManaged public var id: String
    @NSManaged public var listened: Bool
    @NSManaged public var name: String
    @NSManaged public var previewURL: String?
    @NSManaged public var trackNumber: Int16
    @NSManaged public var uri: String
    @NSManaged public var albumId: String
    @NSManaged public var albumNameString: String?
    @NSManaged public var album: Album?

    convenience init?(json: [String: AnyObject], context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entity(forEntityName: "Track", in: CoreDataStack.sharedInstance.managedContext)
        self.init(entity: entity!, insertInto: nil)
        
        guard let name = json["name"] as? String,
            let id = json["id"] as? String,
            let trackNumber = json["track_number"] as? Int,
            let uri = json["uri"] as? String,
            let duration = json["duration_ms"] as? Int else { return nil }
        
        if let albumInfo = json["album"] as? [String: AnyObject] {
            self.album = Album(json: albumInfo)
        }
        
        if let url = json["preview_url"] as? String {
            self.previewURL = url
        }

        self.name = name
        self.id = id
        self.trackNumber = Int16(trackNumber)
        self.uri = uri
        self.duration = Int32(duration)
        self.listened = false
    }
}
