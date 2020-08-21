//
//  SkinFeaturesTableViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 15/07/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CoreSpotlight
import SwiftUI
import Combine

class SkinFeaturesTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet var settingsIcon: UIBarButtonItem!
    
    let defaults = UserDefaults.standard
    
    private var newFeatureSubscriber: AnyCancellable?


    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        guard container != nil else { fatalError("This view needs a persistent container.") }
        initialiseCoreData()
        configureTableView()
        
        setSettingsIcon()
        configureForMac()
        
        let notificationCenter = NotificationCenter.default
        newFeatureSubscriber = notificationCenter.publisher(for: .newFeature)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { notification in
                self.newFeature()
            })
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        checkTC()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        addToSpotlight()
        addHomeScreenShortcutItems()
        view.window?.windowScene?.title! = "Skin Features"
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.title == "Settings" {
            showSettings(activity)
        }
    }
    
    // MARK: - Table View
    
    func configureTableView() {
        tableView.dragDelegate = self
        tableView.register(UINib(nibName: "ConditionsTableViewCell", bundle: nil), forCellReuseIdentifier: "conditionCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mac")
        tableView.allowsMultipleSelectionDuringEditing = true
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let frc = fetchedResultsController {
            return frc.sections!.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchedResultsController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = self.fetchedResultsController?.sections?[section] else {
            return nil
        }
        let name = sectionInfo.name == "0" ? "Ongoing" : "Completed"
        return name
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard let result = self.fetchedResultsController?.section(forSectionIndexTitle: title, at: index) else {
            fatalError("Unable to locate section for \(title) at index: \(index)")
        }
        return result
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let condition = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        #if targetEnvironment(macCatalyst)
        let macCell = tableView.dequeueReusableCell(withIdentifier: "CatalystConditionCell", for: indexPath)
        macCell.textLabel!.text = condition.name
        if condition.entry?.count ?? 0 > 0 {
            if let entry = condition.entry?.lastObject as? Entry {
                if let image = entry.image?.anyObject() as? Attachment {
                    macCell.imageView!.image = UIImage(data: image.thumbnail!)
                    macCell.imageView!.layer.masksToBounds = true
                    macCell.imageView!.layer.cornerRadius = 5
                    macCell.imageView!.clipsToBounds = true
                    macCell.imageView!.contentMode = .scaleAspectFill
                } else {
                    macCell.imageView!.image = nil
                }
            }
        } else {
            if #available(iOS 13.0, *) {
                macCell.imageView!.image = UIImage(systemName: "photo.on.rectangle")
                macCell.imageView!.contentMode = .scaleAspectFit
            } else {
                macCell.imageView!.image = nil
            }
        }
        return macCell
        #endif
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "conditionCell", for: indexPath) as! ConditionsTableViewCell
        let entries = condition.entry
        var entryPluralString = "Entries"
        if entries?.count == 1 {
            entryPluralString = "Entry"
        }
        cell.cellTitleLabel.text = condition.name
        cell.cellLeftLabel.text = condition.areaOfBody
        cell.cellRightLabel.text = "\(entries?.count ?? 0) \(entryPluralString)"
        if condition.entry?.count ?? 0 > 0 {
            if let entry = condition.entry?.lastObject as? Entry {
                if let image = entry.image?.anyObject() as? Attachment {
                    cell.cellImageView.image = UIImage(data: image.thumbnail!)
                    cell.cellImageView.layer.masksToBounds = true
                    cell.cellImageView.layer.cornerRadius = 5
                    cell.cellImageView.clipsToBounds = true
                    cell.cellImageView.contentMode = .scaleAspectFill
                } else {
                    cell.cellImageView.image = nil
                }
            }
        } else {
            if #available(iOS 13.0, *) {
                cell.cellImageView.image = UIImage(systemName: "photo.on.rectangle")
                cell.cellImageView.contentMode = .scaleAspectFit
            } else {
                cell.cellImageView.image = nil
            }
        }
        
        if #available(iOS 13.0, *) {
            if condition.complete == true {
                cell.favouriteImageView.image = UIImage(systemName: "checkmark.circle.fill")
            } else {
                cell.favouriteImageView.image = condition.favourite ? UIImage(systemName: "heart.fill") : nil
            }
        } else {
            // Fallback on earlier versions
        }
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.init(named: "Theme Colour")
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        view.tintColor = UIColor(named: "Theme Colour 2")
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isEditing == true {
            
        } else {
            performSegue(withIdentifier: "showEntries", sender: nil)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let condition = fetchedResultsController.object(at: indexPath)
        let completedAction = UIContextualAction(style: .normal, title: "Mark as Complete") { _,_,_  in
            self.markCompleted(condition: condition)
        }
        if condition.complete == true {
            completedAction.title = "Mark as Ongoing"
        }
        completedAction.backgroundColor = UIColor(named: "Theme Colour")
        let actions = UISwipeActionsConfiguration(actions: [completedAction])
        return actions
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let condition = fetchedResultsController.object(at: indexPath)
            delete(condition: condition, indexPath: indexPath)
        }
    }
    
    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu(condition: self.fetchedResultsController.object(at: indexPath), indexPath: indexPath) // pass condition for use in action
        })
    }
    
    // Allows users to swipe two fingers to select rows
    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        self.setEditing(true, animated: true)
    }
    
    // MARK: - Actions
    
    func checkTC() {
        let launchedBefore = defaults.bool(forKey: "hasLaunchedBefore")
        if !launchedBefore {
            firstTime = true
            print("First launch, setting UserDefault.")
            defaults.set(true, forKey: "hasLaunchedBefore")
            showOnboarding()
        } else {
            if defaults.integer(forKey: "TermsAndConditions") < GlobalVariables().termsAndConditionsCurrentVersion {
                let reviewAction = UIAlertAction(title: "Review Terms and Conditions", style: .default, handler: {_ in self.showOnboarding()})
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {_ in })
                let alertController = UIAlertController(title: "Terms and Conditions", message: "To use this app, you must accept the terms and conditions", preferredStyle: .alert)
                alertController.addAction(reviewAction)
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    var firstTime = false
    
    func showOnboarding() {
        let view = UIHostingController(rootView: OnboardingView(vc: self, stage: 0, confirmed: false))
        view.modalPresentationStyle = .fullScreen
        present(view, animated: false, completion: nil)
    }
    
    func showHelp() {
        //guard firstTime == true else { return }
        let alert = UIAlertController(title: "Tutorial", message: "Would you like to read how to use this app?", preferredStyle: .alert)
        
        let action1 = UIAlertAction(title: "Show Help", style: .default, handler: { _ in
            let view = UIHostingController(rootView: HelpView(showCancel: true, vc: self))
            view.modalPresentationStyle = .automatic
            self.present(UINavigationController(rootViewController: view), animated: true, completion: nil)
        })
        
        let action2 = UIAlertAction(title: "I'll work it out", style: .cancel, handler: nil)
        
        alert.addAction(action1)
        alert.addAction(action2)
        
        present(alert, animated: true, completion: {})
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc func newFeature() {
        performSegue(withIdentifier: "addFeature", sender: self)
    }
    
    func delete(condition: SkinFeature, indexPath: IndexPath) {
        let alert = UIAlertController(title: "Delete Condition", message: "Deleting a condition is permanent.  \n\nIf you would like to archive it, mark it as completed", preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Default action"), style: .destructive, handler: { _ in
             NSLog("The \"Delete\" alert occured.")
            
            // Delete pending notifications
            let notifications = condition.notification
            var notificationArrayString: [String] = []
            for notification in notifications! {
                let notificationAsUUID = notification as! ConditionNotification
                notificationArrayString.append(notificationAsUUID.identifier!.uuidString)
            }
            
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: notificationArrayString)
            
            // Delete condition
            self.container.viewContext.delete(condition)
            self.updateCoreData()
            
            // Clear DetailView
          //  self.entriesViewController?.configureViewEmpty()
         }))
         alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
         
         self.present(alert, animated: true, completion: nil)
    }
    
    func markCompleted(condition: SkinFeature) {
        condition.complete.toggle()
        self.updateCoreData()
    }
    
    
    func setSettingsIcon() {
        if #available(iOS 13.0, *) {
            
        } else {
            settingsIcon.image = UIImage(named: "gear")
        }
    }
    
    
    @objc func showSettings(_ sender: Any?) {
        performSegue(withIdentifier: "showSettings", sender: nil)
    }
    

    // MARK: - Core Data
    
    var container: NSPersistentContainer! // Set by AppDelegate.swift
    var fetchedResultsController: NSFetchedResultsController<SkinFeature>!
    
    func initialiseCoreData() {
        let request = NSFetchRequest<SkinFeature>(entityName: "SkinFeature")
        let completeSort = NSSortDescriptor(key: "complete", ascending: true)
        request.sortDescriptors = [completeSort]
        
        let moc = container.viewContext
        let undoMan = UndoManager.init()
        moc.undoManager = undoMan
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: "complete", cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        @unknown default:
            break
        }
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            break
        }
    }
     
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    
    
    func updateCoreData() {
        do {
        try container.viewContext.save()
        } catch {
        fatalError("Failure to save context: \(error)")
        }
    }
    
    // MARK: - Mac
    func configureForMac() {
        #if targetEnvironment(macCatalyst)
        navigationController?.isToolbarHidden = true
        navigationController?.isNavigationBarHidden = true
        
        #endif
    }
    
    // MARK: - Navigation
    
    //Send condition to entries view
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEntries" || segue.identifier == "showEntriesUnanimated" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = self.fetchedResultsController.object(at: indexPath)
                let newController = (segue.destination as! UINavigationController).topViewController as! EntriesCollectionViewController
                // Send pressed condition to entry view
                newController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                newController.navigationItem.leftItemsSupplementBackButton = true
                newController.condition = object
                newController.managedObjectContext = container.viewContext
                newController.previousController = self
                
            }
        }
        
        if segue.identifier == "addFeaature" {
            let navController = segue.destination as! UINavigationController
            let newController = navController.viewControllers[0] as! AddConditionTableViewController
            // Handoff send
            guard let senderActivity = sender as? NSUserActivity else { print("Handoff error"); return }
            newController.restoreUserActivityState(senderActivity)
        }
        
        if segue.identifier == "showSettings" || segue.identifier == "showSettingsUnanimated" {
            let newController = (segue.destination as! SettingsNavController).viewControllers[0] as! SettingsTableViewController
            newController.conditionsController = self
        }
    }
    
    @IBAction func unwindFromAddCondition(for unwindSegue: UIStoryboardSegue) {
        guard let addConditionTableViewController = unwindSegue.source as? AddConditionTableViewController else {return}
        
        //Get condition instance
        guard let conditionName = addConditionTableViewController.newConditionName else {return}
        guard let conditionArea = addConditionTableViewController.newConditionArea else {return}
        guard let conditionDate = addConditionTableViewController.newConditionDate else {return}
        let uuid = UUID()
        
        let condition = SkinFeature(context: container.viewContext)
        
        // Set value of condition
        condition.setValue(conditionName, forKey: "name")
        condition.setValue(conditionArea, forKey: "areaOfBody")
        condition.setValue(conditionDate, forKey: "startDate")
        condition.setValue(uuid, forKey: "uuid")
        print("UUID: \(uuid)")
        
        updateCoreData()
        
        var feedbackGenerator : UINotificationFeedbackGenerator? = nil
        feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator?.prepare()
        feedbackGenerator?.notificationOccurred(.success)
    }
    
    
    @IBSegueAction func addFeatureSegue(_ coder: NSCoder) -> UIViewController? {
        let coder = coder
        let rootView = AddFeatureView(vc: self, date: Date(), featureName: "", featureArea: "", context: container.viewContext)
        return UIHostingController(coder: coder, rootView: rootView)
    }
    
    func editFeature(feature: SkinFeature) {
       // let coder = coder
        let rootView = AddFeatureView(vc: self, editingSkinFeature: feature, date: feature.startDate!, featureName: feature.name!, featureArea: feature.areaOfBody!, context: container.viewContext)
        present(UIHostingController(rootView: rootView), animated: true, completion: nil)
    }
    
    
    

}


// MARK: - Drag Support

extension SkinFeaturesTableViewController: UITableViewDragDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let selectedCondition = self.fetchedResultsController.object(at: indexPath)
        
        let userActivity = selectedCondition.openDetailUserActivity
        let itemProvider = NSItemProvider(object: selectedCondition.uuid!.uuidString as NSString)
        itemProvider.registerObject(userActivity, visibility: .all)
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = selectedCondition
        
        return [dragItem]
    }
    
}

// MARK: - Context Menus
extension SkinFeaturesTableViewController: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in

            return self.makeContextMenu(condition: nil, indexPath: nil)
        })
    }
    
    
    
    func makeContextMenu(condition: SkinFeature?, indexPath: IndexPath?) -> UIMenu {

        let favourite = UIAction(title: "Favourite") { action in
            condition?.favourite.toggle()
            self.updateCoreData()
            self.tableView.reloadData()
        }
        favourite.image = condition!.favourite ? UIImage(systemName: "heart.slash.fill") : UIImage(systemName: "heart")
        favourite.title = condition!.favourite ? "Remove from Favourites" : "Add to Favourites"
        
        let newWindow = UIAction(title: "Open in New Window", image: UIImage(systemName: "uiwindow.split.2x1")) { action in
            let userActivity = condition?.openDetailUserActivity
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: userActivity, options: nil, errorHandler: nil)
        }
        
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
            self.delete(condition: condition!, indexPath: indexPath!)
        }
        
        let markDone = UIAction(title: "Mark as complete") { action in
            self.markCompleted(condition: condition!)
        }
        markDone.image = condition!.complete ? UIImage(systemName: "multiply.circle") : UIImage(systemName: "checkmark.circle")
        markDone.title = condition!.complete ? "Mark as Ongoing" : "Mark as Complete"
        
        let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil"), handler: { action in
            self.editFeature(feature: condition!)
        })
        
        
        // Create and return a UIMenu with the actions
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIMenu(title: "", children: [favourite, edit, newWindow, markDone, delete])
        } else {
            return UIMenu(title: "", children: [favourite, edit, markDone, delete])
        } // Don't show new window option if not running on iPad
    }
}


// MARK: - Spotlight
extension SkinFeaturesTableViewController {
    func addToSpotlight() {
        let index = CSSearchableIndex.default()
        if defaults.bool(forKey: "showHomeQuickActions") == true {
            
            let attributeSet = CSSearchableItemAttributeSet(itemContentType: "kUTTypeItem")
            
            for condition in fetchedResultsController.fetchedObjects ?? [] {
                attributeSet.title = condition.name
                attributeSet.contentModificationDate = (condition.entry?.lastObject as? Entry)?.date
                let item = CSSearchableItem(uniqueIdentifier: condition.uuid?.uuidString, domainIdentifier: "myConditions", attributeSet: attributeSet)
                index.indexSearchableItems([item], completionHandler: nil)
            }
        } else {
            index.deleteSearchableItems(withIdentifiers: ["myConditions"], completionHandler: nil)
        }
    }
    
    
    func addHomeScreenShortcutItems() {
      /*  #if targetEnvironment(macCatalyst)
        return
        #endif
        var items: [UIApplicationShortcutItem] = []
        if defaults.bool(forKey: "showHomeQuickActions") == true {
            guard let conditions = fetchedResultsController?.fetchedObjects else { return }
            
            let number = conditions.count > 2 ? 2 : conditions.count - 1 // Will give first conditions (up to 3)
            guard number >= 1 else { return }
            
            for conditionNumber in 0 ... number {
                let condition = conditions[conditionNumber] 
                let shortcutItem = UIApplicationShortcutItem(type: "com.Baughan.Chronoderm.opencondition", localizedTitle: condition.name ?? "name", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(systemImageName: "photo"), userInfo: ["conditionUUID": condition.uuid!.uuidString as NSString])
                items.append(shortcutItem)
            }
        }
        UIApplication.shared.shortcutItems = items*/
    }
}
