//
//  Feature.swift
//  Chronoderm
//
//  Created by Nick Baughan on 24/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import Foundation
import CoreData

extension SkinFeature {
    
    static func create(in managedObjectContext: NSManagedObjectContext, name: String, area: String, date: Date){
        let newFeature = self.init(context: managedObjectContext)
        
        newFeature.name = name
        newFeature.startDate = date
        newFeature.areaOfBody = area
        newFeature.uuid = UUID()
        
        do {
            try  managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    static func update(feature: SkinFeature, in managedObjectContext: NSManagedObjectContext, name: String, area: String, date: Date){
        feature.name = name
        feature.areaOfBody = area
        feature.startDate = date
        do {
            try  managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    
    var openDetailUserActivity: NSUserActivity {
        // Create an NSUserActivity from our photo model.
        // Note: The activityType string below must be included in your Info.plist file under the `NSUserActivityTypes` array.
        // More info: https://developer.apple.com/documentation/foundation/nsuseractivity
        let userActivity = NSUserActivity(activityType: "com.Baughan.Chronoderm.openCondition")
        userActivity.title = "openCondition"
        userActivity.userInfo = ["conditionUUID": uuid!.uuidString]
        return userActivity
    }
}
