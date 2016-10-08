//
//  Artist+CoreDataProperties.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/7/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import CoreData


extension Artist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Artist> {
        return NSFetchRequest<Artist>(entityName: "Artist");
    }

    @NSManaged public var name: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var id: String?
    @NSManaged public var artistImage: NSData?
    @NSManaged public var resultNumber: Int16

}
