//
//  ActivityView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 30/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        
        let viewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        viewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            self.isPresented = false }
        
        return viewController
    }
    
    func updateUIViewController(_ activityViewController: UIActivityViewController, context: Context) {
        
    }
}

