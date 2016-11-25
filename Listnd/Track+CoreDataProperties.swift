//
//  Track+CoreDataProperties.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/19/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import CoreData


extension Track {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Track> {
        return NSFetchRequest<Track>(entityName: "Track");
    }

    @NSManaged public var id: String
    @NSManaged public var listened: Bool
    @NSManaged public var name: String
    @NSManaged public var previewURL: String?
    @NSManaged public var trackNumber: Int16
    @NSManaged public var uri: String
    @NSManaged public var duration: Int32
    @NSManaged public var album: Album?

}
