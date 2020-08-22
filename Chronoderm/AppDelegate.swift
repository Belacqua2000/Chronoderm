//
//  AppDelegate.swift
//  Chronoderm
//
//  Created by Nick Baughan on 15/07/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var shortcutItemToProcess: UIApplicationShortcutItem?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Application did finish launching with options")
        // Override point for customization after application launch.
        setUpVCs()
        
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            shortcutItemToProcess = shortcutItem
        }
        
        return true
    }
    
    func setUpVCs() {
        if #available(iOS 13.0, *) {
        } else {
            let splitViewController = self.window!.rootViewController as! SplitViewController
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
            navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            navigationController.topViewController!.navigationItem.leftBarButtonItem?.tintColor = UIColor(named: "Theme Colour")
            
            if let splitVC = window?.rootViewController as? SplitViewController {
                if let navVC = splitVC.viewControllers[0] as? UINavigationController {
                    if let tableVC = navVC.viewControllers[0] as? SkinFeaturesTableViewController {
                        tableVC.container = persistentContainer
                        print("Container set")
                    }
                }
            } else {fatalError("Container not set")}
            splitViewController.preferredDisplayMode = .allVisible
        }
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("Configuration for connecting scene session")
        
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("Application will resign active")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Application did enter background")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("Application will enter foreground")
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("Application did become active")
        // Is there a shortcut item that has not yet been processed?
        if let shortcutItem = shortcutItemToProcess {
            if shortcutItem.type == "com.Baughan.Chronoderm.newCondition" {
                guard let splitVC = window?.rootViewController as? SplitViewController else { return }
                guard let navVC = splitVC.viewControllers[0] as? UINavigationController else { return }
                guard let tableVC = navVC.viewControllers[0] as? SkinFeaturesTableViewController else { return }
                tableVC.performSegue(withIdentifier: "addFeaature", sender: shortcutItem)
            }

            // Reset the shorcut item so it's never processed twice.
            shortcutItemToProcess = nil
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("Application will terminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Home Screen Quick Actions
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("Application, perform action for shortcut item")
        // Alternatively, a shortcut item may be passed in through this delegate method if the app was
        // still in memory when the Home screen quick action was used. Again, store it for processing.
        shortcutItemToProcess = shortcutItem
    }
    
    // MARK: - Handoff
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        print("Will continue user activity with type")
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("Application continue userActivity")
        guard let splitVC = window?.rootViewController as? SplitViewController else { return false }
        guard let navVC = splitVC.viewControllers[0] as? UINavigationController else { return false }
        guard let tableVC = navVC.viewControllers[0] as? SkinFeaturesTableViewController else { return false }
        
        if userActivity.activityType == "com.Baughan.Chronoderm.NewCondition" {
            tableVC.performSegue(withIdentifier: "addFeaature", sender: userActivity) // Performs segue and sends userActivity
            return true
        } else if userActivity.activityType == "com.Baughan.Chronoderm.settings" {
            tableVC.performSegue(withIdentifier: "showSettings", sender: userActivity)
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Auto Nav
    
    func loadAddCondition() {
        
    }
    

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        
            let container = NSPersistentCloudKitContainer(name: "Chronoderm")
        
        // Create a store description for a local store
           let localStoreLocation = URL(fileURLWithPath: "/path/to/local.store")
           let localStoreDescription =
               NSPersistentStoreDescription(url: localStoreLocation)
           localStoreDescription.configuration = "Local"
           
           // Create a store description for a CloudKit-backed local store
           let cloudStoreLocation = URL(fileURLWithPath: "/path/to/cloud.store")
           let cloudStoreDescription =
               NSPersistentStoreDescription(url: cloudStoreLocation)
           cloudStoreDescription.configuration = "Cloud"

           // Set the container options on the cloud store
           cloudStoreDescription.cloudKitContainerOptions =
               NSPersistentCloudKitContainerOptions(
                   containerIdentifier: "com.iCloud.baughan.chronoderm.chronoderm")
           
           // Update the container's list of store descriptions
           container.persistentStoreDescriptions = [
               cloudStoreDescription,
               localStoreDescription
           ]
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                assertionFailure(error.localizedDescription)
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("Core Data stack has been initialized with description: \(storeDescription)")
        }
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

