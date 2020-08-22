//
//  AddPhotoView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 10/07/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI
import UIKit

struct AddPhotoView: UIViewControllerRepresentable {
    
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> CropViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller: CropViewController = storyboard.instantiateViewController(identifier: "addPhotoScene") as! CropViewController
        
        controller.image = image
        controller.didConfirmProtocol = self.makeCoordinator()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CropViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = CropViewController
    
    class Coordinator: NSObject, ConfirmPhoto {
        var parent: AddPhotoView
        
        func didConfirmPhoto(image: UIImage) {
            parent.image = image
        }
        
        init(_ addPhotoView: AddPhotoView) {
            self.parent = addPhotoView
        }
        
    }
    
}
/*
struct AddPhotoView_Previews: PreviewProvider {
    static var previews: some View {
        AddPhotoView(image: Image(systemName: "photo"))
    }
}
*/
