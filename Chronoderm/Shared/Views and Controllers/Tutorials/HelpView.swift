//
//  HelpView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 11/08/2020.
//

import SwiftUI

struct HelpView: View {
    @State var pageNumber: Int = 0
    @State var popoverIsShown: Bool = false
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                HelpViewContent(pageNumber: pageNumber)
                    .multilineTextAlignment(.leading)
            }
            .navigationBarTitle("Add Skin Feature")
            .navigationBarItems(trailing: Button(action: {
                self.popoverIsShown = true
                }) {
                    Image(systemName: "book")
            }
            .popover(isPresented: $popoverIsShown, content: { ContentsView(number: self.$pageNumber) })
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(pageNumber: 0, popoverIsShown: false)
    }
}

struct HelpViewContent: View {
    var pageNumber: Int
    var body: some View {
        ForEach(HelpPages.pages[pageNumber].content!) { item in
            //self.view(pageContent: item)
            Text(item.content)
        }
    }
    
    func view(pageContent: HelpPageContent) -> AnyView {
        switch pageContent.type {
        case .image:
            let image = Image(pageContent.content)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: 600)
            return AnyView(image)
        case .text:
            let text = Text(pageContent.content)
            return AnyView(text)
        }
    }
}

struct ContentsView: View {
    @Binding var number: Int
    var body: some View {
        List(HelpPages.pages) { page in
            HStack {
                Text(page.title)
                Spacer()
                if page.id == self.number {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
