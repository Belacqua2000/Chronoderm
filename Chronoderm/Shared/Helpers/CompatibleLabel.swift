//
//  CompatibleLabel.swift
//  Chronoderm
//
//  Created by Nick Baughan on 30/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI

struct CompatibleLabel: View {
    var symbolName: String
    var text: String
    var body: some View {
        if #available(iOS 14.0, *) {
            Label(text, systemImage: symbolName)
        } else {
            HStack {
                Image(systemName: symbolName)
                Text(text)
            }
        }
    }
}
