//
//  Entry+CoreDataProperties.swift
//  Chronoderm
//
//  Created by Nick Baughan on 19/09/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//
//

import Foundation
import CoreData


extension Entry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry")
    }

    @NSManaged public var date: Date
    @NSManaged public var notes: String?
    @NSManaged public var condition: SkinFeature
    @NSManaged public var image: NSSet?
    @NSManaged public var uuid: UUID?
    
    // Transient property for grouping a table into sections based
    // on day of entity's date. Allows an NSFetchedResultsController
    // to sort by date, but also display the day as the section title.
    //   - Constructs a string of format "YYYYMMDD", where YYYY is the year,
    //     MM is the month, and DD is the day (all integers).

    @objc public var dateSection: String? {
        let currentCalendar = Calendar.current
        self.willAccessValue(forKey: "daySectionIdentifier")
        var sectionIdentifier = ""
        let date = self.date
        
        let month = currentCalendar.component(.month, from: date)
        let year = currentCalendar.component(.year, from: date)

        // Construct integer from year, month, day. Convert to string.
        sectionIdentifier = "\(year * 1000 + month)"
        self.didAccessValue(forKey: "daySectionIdentifier")

        return sectionIdentifier
    }
    
    var openDetailUserActivity: NSUserActivity {
        // Create an NSUserActivity from our photo model.
        // Note: The activityType string below must be included in your Info.plist file under the `NSUserActivityTypes` array.
        // More info: https://developer.apple.com/documentation/foundation/nsuseractivity
        let userActivity = NSUserActivity(activityType: "com.Baughan.MyHealingTest.openentry")
        userActivity.title = "openEntry"
        userActivity.userInfo = ["entryUUID": uuid!.uuidString, "conditionUUID": condition.uuid!.uuidString]
        return userActivity
    }
    
    /*
    static func create(image: UIImage, date: Date, notes: String){
        let newEntry = self.init()
        
        newEntry.image = image
        newEntry.date = date
        newEntry.notes = notes
        newEntry.uuid = UUID()
        
        do {
            try  managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }*/

}

// MARK: Generated accessors for image
extension Entry {

    @objc(addImageObject:)
    @NSManaged public func addToImage(_ value: Attachment)

    @objc(removeImageObject:)
    @NSManaged public func removeFromImage(_ value: Attachment)

    @objc(addImage:)
    @NSManaged public func addToImage(_ values: NSSet)

    @objc(removeImage:)
    @NSManaged public func removeFromImage(_ values: NSSet)

}
