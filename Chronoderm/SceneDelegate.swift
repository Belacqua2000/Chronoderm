//
//  SceneDelegate.swift
//  Chronoderm
//
//  Created by Nick Baughan on 08/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit
import Foundation
import CoreData

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var shortcutItemToProcess: UIApplicationShortcutItem?
    var toolbarDelegate = ToolbarDelegate()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("Will connect to scenesession")
        
        // Looks for Home Screen Quick Action, and acts on it
        #if !targetEnvironment(macCatalyst)
        if let shortcutItem = connectionOptions.shortcutItem {
            shortcutItemToProcess = shortcutItem
        }
        #endif
        
        // Setup split controller
        guard let window = window else { return }
        guard let splitViewController = window.rootViewController as? SplitViewController else { return }
        guard let navigationController = splitViewController.viewControllers.last as? UINavigationController else { return }
        splitViewController.preferredDisplayMode = .allVisible
        splitViewController.primaryBackgroundStyle = .sidebar
        navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navigationController.topViewController?.navigationItem.leftItemsSupplementBackButton = true
        navigationController.topViewController?.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        
        // Setup master controller
        let masterNavVC = splitViewController.viewControllers[0] as! MasterNavController
        let tableVC = masterNavVC.viewControllers[0] as! SkinFeaturesTableViewController
        // Set-up Core Data container
        tableVC.container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        print("Container set")
        
        // Mac Setup
        #if targetEnvironment(macCatalyst)
        guard let windowScene = scene as? UIWindowScene else { return }
        let toolbar = NSToolbar(identifier: "main")
        toolbar.delegate = toolbarDelegate
        toolbar.displayMode = .default
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        
        if let titlebar = windowScene.titlebar {
            titlebar.toolbar = toolbar
            if #available(macCatalyst 14.0, *) {
            titlebar.toolbarStyle = .automatic
            }
        }
        #endif
        
        // If there is a user activity (e.g. drag and drop condition to create view), run the 'configure' function.
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            window.makeKeyAndVisible()
            if !configure(window: window, with: userActivity) {
                print("Failed to restore from \(userActivity)")
            }
        }
    }
    
    
    // Handle user activities sent via Handoff
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if !configure(window: self.window, with: userActivity) {
            print("Unable to complete handoff")
        }
    }
    
    func scene(_ scene: UIScene, didFailToContinueUserActivityWithType userActivityType: String, error: Error) {
        print(error)
    }
    
    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        print("State restoration activity for scene")
        return scene.userActivity
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        print("Scene perform action for shortcut item")
        shortcutItemToProcess = shortcutItem
    }
    
    // Handle userActivity, regardless of origin
    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        print("Configure with activity")
        
        switch activity.activityType {
        case "com.Baughan.Chronoderm.openCondition" :
            guard let conditionID = activity.userInfo?["conditionUUID"] as? String else { return false }
            return openCondition(conditionID: conditionID)!
        case "com.Baughan.Chronoderm.openentry" :
            guard let entryID = activity.userInfo?["entryUUID"] as? String else { return false }
            guard let conditionID = activity.userInfo?["conditionUUID"] as? String else { return false }
            return openEntry(entryID: entryID, conditionID: conditionID)!
        case "com.Baughan.Chronoderm.settings" :
            return openSettings()!
        case "com.Baughan.Chronoderm.tutorial" :
            return openTutorial(activity: activity)!
        case "com.Baughan.Chronoderm.help" :
            return openHelp(activity: activity)!
        case "com.Baughan.Chronoderm.newcondition" :
            return openAddEntry()!
        default:
            return false
        }
    }

     func sceneDidDisconnect(_ scene: UIScene) {
        print("Scene did disconnect")
         // Called as the scene is being released by the system.
         // This occurs shortly after the scene enters the background, or when its session is discarded.
         // Release any resources associated with this scene that can be re-created the next time the scene connects.
         // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
     }

     func sceneDidBecomeActive(_ scene: UIScene) {
        print("Scene did become active")
        guard let splitVC = window?.rootViewController as? SplitViewController else { return }
        guard let navVC = splitVC.viewControllers[0] as? UINavigationController else { return }
        guard let tableVC = navVC.viewControllers[0] as? SkinFeaturesTableViewController else { return }
        
        // Is there a shortcut item that has not yet been processed?
        if let shortcutItem = shortcutItemToProcess {
            if shortcutItem.type == "com.Baughan.Chronoderm.newCondition" {
                tableVC.performSegue(withIdentifier: "addFeaature", sender: shortcutItem)
            }
            
            if shortcutItem.type == "com.Baughan.Chronoderm.settings" {
                tableVC.performSegue(withIdentifier: "showSettings", sender: shortcutItem)
            }
            // Reset the shorcut item so it's never processed twice.
            shortcutItemToProcess = nil
        }
         // Called when the scene has moved from an inactive state to an active state.
         // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
     }

     func sceneWillResignActive(_ scene: UIScene) {
        print("Scene will resign active")
         // Called when the scene will move from an active state to an inactive state.
         // This may occur due to temporary interruptions (ex. an incoming phone call).
        if let splitController = window!.rootViewController as? SplitViewController {
            if let navController = splitController.viewControllers[0] as? MasterNavController {
                // Fetch the user activity from our detail view controller so restore for later.
                if let conditionsVC = navController.viewControllers[0] as? SkinFeaturesTableViewController {
                    if let settingsnavVC = conditionsVC.presentedViewController as? SettingsNavController {
                        if let settingsVC = settingsnavVC.topViewController as? SettingsTableViewController {
                            if let tutorialVC = settingsVC.presentedViewController as? OnboardingViewController {
                                scene.userActivity = tutorialVC.userActivity
                            } else {
                                scene.userActivity = settingsVC.settingsUserActivity
                            }
                        }
                    }
                }
            }
        }
     }

     func sceneWillEnterForeground(_ scene: UIScene) {
        print("Scene will enter foreground")
        
         // Called as the scene transitions from the background to the foreground.
         // Use this method to undo the changes made on entering the background.
     }

     func sceneDidEnterBackground(_ scene: UIScene) {
        print("Scene did enter background")
         // Called as the scene transitions from the foreground to the background.
         // Use this method to save data, release shared resources, and store enough scene-specific state information
         // to restore the scene back to its current state.

         // Save changes in the application's managed object context when the application transitions to the background.
         (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    
    
    // MARK: - View Navigation
    func openCondition(conditionID: String) -> Bool? {
        let splitVC = window!.rootViewController as! SplitViewController
        let navVC = splitVC.viewControllers[0] as! UINavigationController
        let conditionsVC = navVC.viewControllers[0] as! SkinFeaturesTableViewController
        
        guard let condition = conditionsVC.fetchedResultsController.fetchedObjects!.first(where: { $0.uuid!.uuidString == conditionID } ) else { return false }  // Searches for the position of the condition to load in the list
        
        let indexPath = conditionsVC.fetchedResultsController.indexPath(forObject: condition) // Gets indexPath of the condition
        
        navVC.popToRootViewController(animated: false)
        
        // Row is selected and segue performed.
        conditionsVC.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        
        conditionsVC.performSegue(withIdentifier: "showEntries", sender: self)
        return true
    }
    
    func openAddEntry() -> Bool? {
        let splitVC = window!.rootViewController as! SplitViewController
        let navVC = splitVC.viewControllers[0] as! UINavigationController
        let conditionsVC = navVC.viewControllers[0] as! SkinFeaturesTableViewController
        conditionsVC.performSegue(withIdentifier: "addFeaature", sender: nil)
        return true
    }
    
    func openEntry(entryID: String, conditionID: String) -> Bool? {
        guard openCondition(conditionID: conditionID)! else { return false }
        
        let splitVC = window!.rootViewController as! SplitViewController
        let navVC = splitVC.viewControllers[0] as! UINavigationController
        let entryVC = navVC.viewControllers[1] as! EntriesCollectionViewController
        entryVC.initialiseCoreData()
        guard let entry = entryVC.fetchedResultsController?.fetchedObjects?.first(where: { $0.uuid?.uuidString == entryID } ) else { return false }  // Searches for the position of the entry to load in the list
        let indexPath = entryVC.fetchedResultsController?.indexPath(forObject: entry) // Gets indexPath of the entry
        entryVC.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
        
        entryVC.performSegue(withIdentifier: "showEntryUnanimated", sender: self)
        
        return true
    }
    
    func openSettings() -> Bool? {
        let splitVC = window!.rootViewController as! SplitViewController
        let navVC = splitVC.viewControllers[0] as! UINavigationController
        let conditionsVC = navVC.visibleViewController as! SkinFeaturesTableViewController
        //self.window?.makeKeyAndVisible()
        conditionsVC.performSegue(withIdentifier: "showSettingsUnanimated", sender: nil)
        return true
    }
    
    
    func openTutorial(activity: NSUserActivity) -> Bool? {
        /* guard openSettings()! else { return false }
        
        let splitVC = self.window!.rootViewController as! SplitViewController
        let navVC = splitVC.viewControllers[0] as! UINavigationController
        let settingsVC = navVC.visibleViewController as? SettingsTableViewController
        settingsVC?.performSegue(withIdentifier: "showTutorial", sender: nil)
        let tutorialVC = settingsVC?.presentedViewController as? OnboardingViewController
        tutorialVC?.restoreUserActivityState(activity)
 */
        return false
    }
    
    func openHelp(activity: NSUserActivity) -> Bool? {
        guard openSettings()! else { return false }
        let splitVC = self.window!.rootViewController as! SplitViewController
        let navVC = splitVC.viewControllers[0] as! UINavigationController
        let settingsVC = navVC.visibleViewController as? SettingsTableViewController
        settingsVC?.performSegue(withIdentifier: "showHelp", sender: nil)
        let helpVC = navVC.visibleViewController as? HelpViewController
        helpVC?.restoreUserActivityState(activity)
        return true
    }
}
