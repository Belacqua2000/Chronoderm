//
//  DetailView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 23/08/2020.
//

import SwiftUI
import UIKit

@available(iOS 14.0, *)
struct DetailView: View {
    @ObservedObject var skinFeature: SkinFeature
    @State var entryNumber: Int = 0
    @State var scale: CGFloat = 1
    var entry: Entry? {
        guard let entries = skinFeature.entry?.array as? [Entry] else { return nil }
        return entries[entryNumber]
    }
    var image: Image {
        let attachment = entry!.image?.anyObject() as! Attachment
        let fullImage = (attachment.fullImage?.fullImage!)!
        return Image(uiImage: UIImage(data: fullImage)!)
    }
    var body: some View {
        ZStack {
            ScrollView {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(scale)
                    .gesture(MagnificationGesture()
                                .onChanged({ value in
                                    scale = value.magnitude
                                }))
                VStack {
                    Text("Title")
                    Spacer()
                    Text("Notes")
                }
            }
        }
        .navigationTitle("Entry \(entryNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    nextImage()
                } label: {
                    Image(systemName: "chevron.left")
                }
                Button {
                    nextImage()
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
        }
    }
    func nextImage() {
        
    }
}
/*
 @available(iOS 14.0, *)
 struct DetailView_Previews: PreviewProvider {
 static var previews: some View {
 DetailView(skinFeature: <#SkinFeature#>)
 }
 }
 */
