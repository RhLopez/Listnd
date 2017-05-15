//
//  Album+CoreDataProperties.swift
//  
//
//  Created by Ramiro H Lopez on 5/14/17.
//
//

import Foundation
import CoreData


extension Album {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Album> {
        return NSFetchRequest<Album>(entityName: "Album")
    }

    @NSManaged public var albumImage: NSData?
    @NSManaged public var id: String
    @NSManaged public var imageURL: String?
    @NSManaged public var listened: Bool
    @NSManaged public var listenedCount: Int16
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var uri: String
    @NSManaged public var artist: Artist
    @NSManaged public var tracks: NSOrderedSet?
    
    convenience init?(json: [String: Any]) {
        let entity = NSEntityDescription.entity(forEntityName: "Album", in: CoreDataStack.sharedInstance.managedContext)
        self.init(entity: entity!, insertInto: nil)
        
        guard let name = json["name"] as? String,
            let id = json["id"] as? String,
            let uri = json["uri"] as? String,
            let type = json["type"] as? String,
            let images = json["images"] as? [[String: AnyObject]],
            let artistInfo = json["artists"] as? [[String:AnyObject]] else { return nil }
        
        let artist = artistInfo.flatMap { Artist(json: $0, context: nil) }
        
        self.artist = artist.first!
        self.name = name
        self.id = id
        self.uri = uri
        self.type = type
        self.imageURL = parseImageUrl(data: images)
    }
    
    func parseImageUrl(data: [[String: AnyObject]]) -> String? {
        if data.isEmpty {
            return nil
        }
        
        let item = data.first!
        guard let url = item["url"] as? String else {
            return nil
        }
        
        return url
    }

}

// MARK: Generated accessors for tracks
extension Album {

    @objc(insertObject:inTracksAtIndex:)
    @NSManaged public func insertIntoTracks(_ value: Track, at idx: Int)

    @objc(removeObjectFromTracksAtIndex:)
    @NSManaged public func removeFromTracks(at idx: Int)

    @objc(insertTracks:atIndexes:)
    @NSManaged public func insertIntoTracks(_ values: [Track], at indexes: NSIndexSet)

    @objc(removeTracksAtIndexes:)
    @NSManaged public func removeFromTracks(at indexes: NSIndexSet)

    @objc(replaceObjectInTracksAtIndex:withObject:)
    @NSManaged public func replaceTracks(at idx: Int, with value: Track)

    @objc(replaceTracksAtIndexes:withTracks:)
    @NSManaged public func replaceTracks(at indexes: NSIndexSet, with values: [Track])

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: Track)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: Track)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSOrderedSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSOrderedSet)

}
