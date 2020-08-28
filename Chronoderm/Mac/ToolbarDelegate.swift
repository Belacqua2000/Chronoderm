//
//  ToolbarDelegate.swift
//  Chronoderm
//
//  Created by Nick Baughan on 01/08/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import UIKit

class ToolbarDelegate: NSObject {

    
}

#if targetEnvironment(macCatalyst)
extension NSToolbarItem.Identifier {
    static let newFeature = NSToolbarItem.Identifier("com.baughan.chronoderm.newFeature")
    static let reminders = NSToolbarItem.Identifier("com.baughan.chronoderm.reminders")
    static let createPDF = NSToolbarItem.Identifier("com.baughan.chronoderm.createPDF")
    static let toggleComplete = NSToolbarItem.Identifier("com.baughan.chronoderm.toggleComplete")
}

extension ToolbarDelegate {
    
    @objc
    func newFeature(_ sender: Any?) {
        NotificationCenter.default.post(name: .newFeature, object: self)
    }
    
    @objc
    func reminders(_ sender: Any?) {
        NotificationCenter.default.post(name: .reminders, object: self)
    }
    
    @objc
    func createPDF(_ sender: Any?) {
        NotificationCenter.default.post(name: .createPDF, object: self)
    }
    
    @objc
    func toggleComplete(_ sender: Any?) {
        NotificationCenter.default.post(name: .createPDF, object: self)
    }
    
}
@available(iOS 14, *)
extension ToolbarDelegate: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            let identifiers: [NSToolbarItem.Identifier] = [
                //.flexibleSpace,
                //.newFeature,
                //.primarySidebarTrackingSeparatorItemIdentifier,
                .toggleSidebar,
                .flexibleSpace,
                .reminders,
                .createPDF
            ]
            return identifiers
        }
        
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let identifiers: [NSToolbarItem.Identifier] = [
            .toggleSidebar,
            //.primarySidebarTrackingSeparatorItemIdentifier,
            .newFeature,
            .reminders,
            .createPDF,
            .flexibleSpace,
            .space,
            .toggleComplete
        ]
            return identifiers
        }
    
    func toolbar(_ toolbar: NSToolbar,
                     itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                     willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
            
            var toolbarItem: NSToolbarItem?
            
            switch itemIdentifier {
            case .toggleSidebar:
                toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
                
            case .newFeature:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.image = UIImage(systemName: "plus")
                item.isBordered = true
                item.label = "New Skin Feature"
                item.action = #selector(newFeature(_:))
                item.target = self
                toolbarItem = item
                
            case .reminders:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.image = UIImage(systemName: "bell")
                item.isBordered = true
                item.label = "Reminders"
                item.action = #selector(reminders(_:))
                item.target = self
                toolbarItem = item
                
            case .createPDF:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.image = UIImage(systemName: "doc.richtext")
                item.isBordered = true
                item.label = "Generate PDF"
                item.action = #selector(createPDF(_:))
                item.target = self
                toolbarItem = item
                
            case .toggleComplete:
                let item = NSToolbarItem(itemIdentifier: itemIdentifier)
                item.image = UIImage(systemName: "checkmark")
                item.isBordered = true
                item.label = "Mark Complete"
                item.action = #selector(toggleComplete(_:))
                item.target = self
                toolbarItem = item
                
            default:
                toolbarItem = nil
            }
            
            return toolbarItem
        }
        
}
#endif
