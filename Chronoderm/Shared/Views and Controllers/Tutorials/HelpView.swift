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
            HelpViewContent(pageNumber: pageNumber)
                .navigationBarTitle("Help", displayMode: .inline)
                .navigationBarItems(trailing: Button(action: {
                    self.popoverIsShown = true
                }) {
                    Image(systemName: "book")
                    .padding()
                }
                .popover(isPresented: $popoverIsShown, content: { ContentsView(isShown: self.$popoverIsShown, number: self.$pageNumber) })
            )
    }
}

struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(pageNumber: 4, popoverIsShown: false)
    }
}

struct HelpViewContent: View {
    var pageNumber: Int
    var body: some View {
        ScrollView() {
            Text(HelpPages.pages[pageNumber].title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            VStack() {
            ForEach(HelpPages.pages[pageNumber].content!) { item in
                self.view(pageContent: item)
            }
            }
            //.padding(.horizontal)
        }
    }
    
    func view(pageContent: HelpPageContent) -> AnyView {
        switch pageContent.type {
        case .image:
            let image = Image(pageContent.content)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .border(LinearGradient(gradient: Gradient(colors: [Color("Theme Colour"), Color("Theme Colour 2")]), startPoint: .top, endPoint: .bottom), width: 5)
            return AnyView(image)
        case .text:
            let text = Text(pageContent.content)
                .multilineTextAlignment(.leading)
            return AnyView(text)
        }
    }
}

struct ContentsView: View {
    @Binding var isShown: Bool
    @Binding var number: Int
    var body: some View {
        List() {
            ForEach(0..<HelpPages.pages.count) { page in
                HStack {
                    Button(HelpPages.pages[page].title) {
                        self.changePage(page: page)
                    }
                    Spacer()
                    if HelpPages.pages[page].id == self.number {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        //.frame(width: 400.0, height: 600.0)
    }
    
    func changePage(page: Int) {
        isShown = false
        number = page
    }
}
