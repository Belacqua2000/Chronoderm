//
//  GlobalVariables.swift
//  Chronoderm
//
//  Created by Nick Baughan on 07/08/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import Foundation

struct GlobalVariables {
    let termsAndConditionsCurrentVersion = 1
    
    // Current version and build number from info.plist
    var currentVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    var currentBuild: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}
