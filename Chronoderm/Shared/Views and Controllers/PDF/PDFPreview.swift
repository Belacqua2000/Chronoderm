//
//  PDFPreview.swift
//  Chronoderm
//
//  Created by Nick Baughan on 30/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI

struct PDFPreview: View {
    var entriesPerPage: Int
    var showNotes: Bool
    var showDate: Bool
    var body: some View {
        VStack {
            ForEach(0 ..< entriesPerPage, id: \.self) {_ in
                VStack(alignment: .leading) {
                    self.showDate ? Text("1st January 1970").bold() : Text("")
                    HStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                        self.showNotes ? Text("Lorum ipsum dolor est") : Text("")
                    }
                }
                .font(.footnote)
            }
            .padding(.all, 4.0)
        }
    }
}

struct PDFPreview_Previews: PreviewProvider {
    static var previews: some View {
        PDFPreview(entriesPerPage: 3, showNotes: true, showDate: true)
    }
}

