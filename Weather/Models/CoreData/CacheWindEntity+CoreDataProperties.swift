//
//  CacheWindEntity+CoreDataProperties.swift
//  
//
//  Created by Александр Кравченков on 16.10.2020.
//
//

import Foundation
import CoreData

extension CacheWindEntity {

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<CacheWindEntity> {
        return NSFetchRequest<CacheWindEntity>(entityName: "CacheWindEntity")
    }

    @NSManaged public var speed: Double
    @NSManaged public var direction: NSNumber?
    @NSManaged public var gust: NSNumber?
    @NSManaged public var city: CacheCityDetailedWeatherEntity?

}
