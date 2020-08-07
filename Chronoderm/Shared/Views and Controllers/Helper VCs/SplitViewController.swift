//
//  SplitViewController.swift
//  Chronoderm
//
//  Created by Nick Baughan on 20/08/2019.
//  Copyright © 2019 Nick Baughan. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func awakeFromNib() {
        super.awakeFromNib()
        delegate = self
        preferredDisplayMode = .allVisible
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        primaryBackgroundStyle = .sidebar
        #else
        setDisplayMode()
        #endif
        
        if #available(iOS 13.0, *) {
            let symbolConfig = UIImage.SymbolConfiguration(weight: .black)
            tabBarItem.image = UIImage(systemName: "plus", withConfiguration: symbolConfig)
            tabBarItem.selectedImage = UIImage(systemName: "plus", withConfiguration: symbolConfig)
        } else {
            
        }
    }
    
    override class func awakeFromNib() {
    }
    
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    

    // MARK: - Keyboard Shortcuts
    let detailViewKeyCommands = [UIKeyCommand(input: "H", modifierFlags: [.command, .alternate], action: #selector(DetailViewController.toggleInterface)), UIKeyCommand(input: "N", modifierFlags: [.command], action: #selector(SkinFeaturesTableViewController.newFeature))]
    
    let conditionKeyCommands: [UIKeyCommand] = [UIKeyCommand(input: ",", modifierFlags: .command, action: #selector(SkinFeaturesTableViewController.showSettings(_:)))]
    
    
    override var keyCommands: [UIKeyCommand]? {
        detailViewKeyCommands[0].discoverabilityTitle = "Hide Interface"
        detailViewKeyCommands[1].discoverabilityTitle = "Add Condition"
        conditionKeyCommands[0].discoverabilityTitle = "Show Settings"
        return conditionKeyCommands
    }
    
    // MARK: - Delegate
    func setDelegate() {
        self.delegate = self
    }
    
    func setDisplayMode() {
        preferredDisplayMode = .allVisible
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        print("Split view controller function")
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? EntriesCollectionViewController else { return false }
        if topAsDetailController.condition == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }
}

// MARK: - NSToolbar
#if targetEnvironment(macCatalyst)
extension SplitViewController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if (itemIdentifier == NSToolbarItem.Identifier(rawValue: "backButton")) {
            let backButton = NSToolbarItem.init(itemIdentifier: NSToolbarItem.Identifier("backButton"), barButtonItem: .init(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(toolbarGroupSelectionChanged)))
            
            backButton.label = "Back"
            backButton.isEnabled = false
            
            return backButton
            
        } else if (itemIdentifier == NSToolbarItem.Identifier(rawValue: "addCondition")) {
            let newCondition = NSToolbarItem.init(itemIdentifier: NSToolbarItem.Identifier("addCondition"), barButtonItem: .init(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addFeature)))
            
            newCondition.label = "New Feature"
            
            return newCondition
            
        } else if (itemIdentifier == NSToolbarItem.Identifier(rawValue: "reminders")) {
            let reminderButton = NSToolbarItem.init(itemIdentifier: NSToolbarItem.Identifier("reminders"), barButtonItem: .init(image: UIImage(systemName: "bell"), style: .plain, target: self, action: #selector(reminders)))
            
            reminderButton.label = "Reminders"
            
            return reminderButton
            
        } else if (itemIdentifier == NSToolbarItem.Identifier(rawValue: "pdf")) {
            let pdfButton = NSToolbarItem.init(itemIdentifier: NSToolbarItem.Identifier("pdf"), barButtonItem: .init(image: UIImage(systemName: "doc.richtext"), style: .plain, target: self, action: #selector(pdf)))
            
            pdfButton.label = "Create PDF"
            
            return pdfButton
            
        }
            return nil
        }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier(rawValue: "backButton"), NSToolbarItem.Identifier.toggleSidebar, NSToolbarItem.Identifier(rawValue: "addCondition"), NSToolbarItem.Identifier.flexibleSpace, NSToolbarItem.Identifier(rawValue: "reminders"), NSToolbarItem.Identifier(rawValue: "pdf")]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.toolbarDefaultItemIdentifiers(toolbar)
    }
    
    
    @objc func toolbarGroupSelectionChanged(sender: NSToolbarItemGroup) {
        let detailNavVC = self.viewControllers[1] as! DetailNavController
        detailNavVC.popToRootViewController(animated: true)
    }
    
    @objc func addFeature(sender: NSToolbarItemGroup) {
        let masterNavVC = self.viewControllers[0] as! MasterNavController
        let conditionVC = masterNavVC.viewControllers[0] as! SkinFeaturesTableViewController
        conditionVC.newFeature()
    }
    
    @objc func addEntry(sender: NSToolbarItemGroup) {
        let detailNavVC = self.viewControllers[1] as! DetailNavController
        let entryVC = detailNavVC.viewControllers[1] as! EntriesCollectionViewController
        // entryVC.addEntry()
    }
    
    @objc func reminders(sender: NSToolbarItemGroup) {
        let detailNavVC = self.viewControllers[1] as! DetailNavController
        let entryVC = detailNavVC.viewControllers[0] as! EntriesCollectionViewController
        entryVC.showReminders()
    }
    
    @objc func pdf(sender: NSToolbarItemGroup) {
        let detailNavVC = self.viewControllers[1] as! DetailNavController
        let entryVC = detailNavVC.viewControllers[0] as! EntriesCollectionViewController
        entryVC.generatePDF()
    }
    
}
#endif
