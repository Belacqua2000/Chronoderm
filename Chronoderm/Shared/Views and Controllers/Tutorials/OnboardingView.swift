//
//  OnboardingView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 29/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI
import Foundation

struct OnboardingView: View {
    var vc: UIViewController?
    @State var stage: Int = 0
    @State private var maxStage: Int = 4
    @State var confirmed: Bool = false
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image("App Icon Inside")
                    .resizable()
                    .frame(width: 50.0, height: 50.0)
                    .cornerRadius(8.0)
                
                Text("Chronoderm")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("Theme Colour"))
                    
            }
            
            Spacer()
            
            ZStack {
                TextAndImage(
                    text: """
Your skin is a vital and complex part of your body.

It acts as a barrier to infections, can sense your environment, and regulate temperature.  Changes in your skin can act as an important indicator into your health.
""",
                    image: Image(systemName: "staroflife.fill"),
                    index: 0,
                    currentStage: $stage)
                
                TextAndImage(
                    text: """
Chronoderm is an app which can help you to keep track of visual changes to your skin.

Taking photos regularly can make it easier to see how your skin is changing.
""",
                    image: Image(systemName: "camera"),
                    index: 1,
                    currentStage: $stage)
                
                TextAndImage(
                    text: """
Examples of skin features which you can monitor are:
\u{2022} Moles and freckles
\u{2022} Wounds and injuries
\u{2022} Rashes, acne, and rosacea
""",
                    image: Image(systemName: "bandage.fill"),
                    index: 2,
                    currentStage: $stage)
                
                TextAndImage(
                    text: """
A customisable summary of your skin features can be generated to make it easy to share with others, such as healthcare professionals or family members.
""",
                    image: Image(systemName: "doc.richtext"),
                    index: 3,
                    currentStage: $stage)

                VStack {
                    TextAndImage(
                        text: """
    This app does not analyse your skin to give a diagnosis.

    If you are worried about how your skin is changing, please seek advice from a healthcare professional.
    This app is designed to be used by individuals for their personal use.
    """,
                        image: Image(systemName: "exclamationmark.triangle"),
                        index: 4,
                        currentStage: $stage)
                    Toggle("Confirm T and Cs", isOn: $confirmed)
                        .opacity(stage == 4 ? 1 : 0)
                }
            }
            .frame(maxWidth: 600)
            
            Spacer()
            
            HStack {
                Button(action: {self.stage -= 1}, label: {
                    Text("Previous")
                })
                .frame(width: 100.0)
                .disabled(stage == 0)
                .padding()
                .background(stage == 0 ? Color(.gray) : Color("Theme Colour 2"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .animation(.easeInOut)
                
                if stage != maxStage {
                    Button(action: {self.stage += 1}, label: {
                        Text("Next")
                    })
                    .frame(width: 100.0)
                    .disabled(stage == maxStage)
                    .padding()
                    .background(Color("Theme Colour 2"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    Button(action: {self.dismiss()}, label: {
                        Text("Get Started")
                    })
                    .frame(width: 100.0)
                    .disabled(!confirmed)
                    .padding()
                    .background(confirmed ? Color.green : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .animation(.easeInOut)
                }
            }
            
        }
        .padding(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        
    }
    
    func dismiss() {
        guard confirmed else { print("T and C not confirmed"); return }
        let defaults = UserDefaults.standard
        defaults.setValue(GlobalVariables().termsAndConditionsCurrentVersion, forKey: "TermsAndConditions")
        vc?.presentedViewController?.dismiss(animated: true, completion: nil)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingView()
                .previewDevice(PreviewDevice(rawValue: "iPhone SE (2nd generation)"))
                .previewDisplayName("iPhone SE")
            OnboardingView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 11"))
                .previewDisplayName("iPhone 11")
        }
    }
}

struct TutorialText: View {
    var body: some View {
        Text("""
Your skin is a vital and complex part of your body.  It acts as a barrier to infections, can sense your environment, and regulate temperature.  Changes in your skin can act as an important indicator into your health.

Chronoderm is an app which can help you to keep track of visual changes to your skin.  Taking photos regularly can make it easier to see how your skin is changing.

Examples of skin features which you can monitor are:
\u{2022} Moles and freckles
\u{2022} Wounds and injuries
\u{2022} Rashes, acne, and rosacea

A customisable summary of your skin features can be generated to make it easy to share with others, such as healthcare professionals or family members.

To get started, press the + button in the bottom toolbar to track a new skin feature.

Entries can be added to each area of skin to allow you easily record how your skin looked, along with any additional notes.

For more detailed instructions, please see the help section within the settings menu.
""")
    }
}

struct DisclosureText: View {
    var body: some View {
        Text("""
This app does not analyse your skin to give a diagnosis.  If you are worried about how your skin is changing, please seek advice from a healthcare professional.
This app is designed to be used by individuals for their personal use.
""")
            .font(.footnote)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground).opacity(0.9))
    }
}

struct TextAndImage: View {
    @State var text: String
    @State var image: Image
    @State var index: Int
    @Binding var currentStage: Int
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100.0, height: 100.0)
            ScrollView {
                Text(text)
                    .font(.system(size: 20.0))
                    .fontWeight(.heavy)
                    .animation(nil)
            }
            .frame(height: 250.0)
            Spacer()
        }
        .opacity(currentStage == index ? 1 : 0)
        .animation(.easeInOut)
    }
}
