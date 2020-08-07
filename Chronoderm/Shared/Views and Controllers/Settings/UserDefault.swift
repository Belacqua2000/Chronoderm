//
//  UserDefault.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import Foundation

class userDefault: ObservableObject {
    @Published var cameraOverlay = UserDefaults.standard.bool(forKey: "CameraOverlayIsShown") {
        didSet {
            UserDefaults.standard.set(cameraOverlay, forKey: "CameraOverlayIsShown")
        }
    }
    init() {
        self.cameraOverlay = UserDefaults.standard.bool(forKey: "CameraOverlayIsShown")
    }
}


extension UserDefaults {
    @objc dynamic var CameraOverlayIsShown: Bool {
        return bool(forKey: "CameraOverlayIsShown")
    }
    
    @objc dynamic var saveImageToPhotos: Bool {
            return bool(forKey: "saveImageToPhotos")
        }
        
    @objc dynamic var showHomeQuickActions: Bool {
        return bool(forKey: "showHomeQuickActions")
    }
    
    @objc dynamic var indexSpotlight: Bool {
        return bool(forKey: "indexSpotlight")
    }
}
