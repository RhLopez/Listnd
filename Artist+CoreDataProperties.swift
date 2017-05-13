//
//  Artist+CoreDataProperties.swift
//  
//
//  Created by Ramiro H Lopez on 4/29/17.
//
//

import Foundation
import CoreData


extension Artist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Artist> {
        return NSFetchRequest<Artist>(entityName: "Artist")
    }

    @NSManaged public var artistImage: NSData?
    @NSManaged public var id: String
    @NSManaged public var imageURL: String?
    @NSManaged public var listened: Bool
    @NSManaged public var name: String
    @NSManaged public var albumCount: Int16
    @NSManaged public var albums: NSOrderedSet?
    
    convenience init?(json: [String: AnyObject], context: NSManagedObjectContext?) {
        let entity = NSEntityDescription.entity(forEntityName: "Artist", in: CoreDataStack.sharedInstance.managedContext)
        self.init(entity: entity!, insertInto: nil)
        guard let id = json["id"] as? String,
            let name = json["name"] as? String else { return nil }
        
        self.id = id
        self.name = name
        self.listened = false
        
        if let images = json["images"] as? [[String: AnyObject]] {
            imageURL = parseImageUrl(data: images)
        }
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

// MARK: Generated accessors for albums
extension Artist {

    @objc(insertObject:inAlbumsAtIndex:)
    @NSManaged public func insertIntoAlbums(_ value: Album, at idx: Int)

    @objc(removeObjectFromAlbumsAtIndex:)
    @NSManaged public func removeFromAlbums(at idx: Int)

    @objc(insertAlbums:atIndexes:)
    @NSManaged public func insertIntoAlbums(_ values: [Album], at indexes: NSIndexSet)

    @objc(removeAlbumsAtIndexes:)
    @NSManaged public func removeFromAlbums(at indexes: NSIndexSet)

    @objc(replaceObjectInAlbumsAtIndex:withObject:)
    @NSManaged public func replaceAlbums(at idx: Int, with value: Album)

    @objc(replaceAlbumsAtIndexes:withAlbums:)
    @NSManaged public func replaceAlbums(at indexes: NSIndexSet, with values: [Album])

    @objc(addAlbumsObject:)
    @NSManaged public func addToAlbums(_ value: Album)

    @objc(removeAlbumsObject:)
    @NSManaged public func removeFromAlbums(_ value: Album)

    @objc(addAlbums:)
    @NSManaged public func addToAlbums(_ values: NSOrderedSet)

    @objc(removeAlbums:)
    @NSManaged public func removeFromAlbums(_ values: NSOrderedSet)

}
