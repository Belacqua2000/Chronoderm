//
//  MenuBuilder.swift
//  Chronoderm
//
//  Created by Nick Baughan on 06/08/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import UIKit

extension AppDelegate {
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        // Check that the builder is building a system menu, and not a context menu.
        guard builder.system == UIMenuSystem.main else { return }
        
        let newFeatureCommand = UIKeyCommand(title: "New Skin Feature", image: nil, action: #selector(newFeature(_:)), input: "n", modifierFlags: [.command, .shift])
        let newFeatureMenu = UIMenu(title: "", options: .displayInline, children: [newFeatureCommand])
        builder.insertChild(newFeatureMenu, atStartOfMenu: .file)
    }
    
    @objc
        func newFeature(_ sender: Any?) {
            NotificationCenter.default.post(name: .newFeature, object: self)
        }
    
}
