//
//  SkinFeaturesCellView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI

struct SkinFeaturesCellView: View {
    var feature: SkinFeature
    var body: some View {
        HStack {
            Image(systemName: "photo.on.rectangle")
                .aspectRatio(1.0, contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
            VStack(alignment: .leading) {
                HStack {
                    Text(feature.name!)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "heart.fill")
                }
                HStack {
                    Text("Area")
                    Spacer()
                    Text("1")
                }
            }
        }
        .padding()
    }
}
/*
struct AreasCellView_Previews: PreviewProvider {
    static var previews: some View {
        SkinFeaturesCellView()
    }
}*/
