//
//  RemindersView.swift
//  Chronoderm
//
//  Created by Nick Baughan on 21/06/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import SwiftUI

struct RemindersView: View {
    @State var remindersIsOn: Bool
    @State var remindersTime: Date
    //@State var daysSelected: [String:Bool] = ["Monday": false, "Tuesday": false, "Wednesday": false, "Thursday": false, "Friday": false, "Saturday": false, "Sunday": false]
    
    @State private var mondayOn = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Toggle(isOn: $remindersIsOn) {
                        remindersIsOn ? CompatibleLabel(symbolName: "bell", text: "Reminders On") : CompatibleLabel(symbolName: "bell", text: "Reminders Off")
                    }
                }
                Section {
                    DatePicker(selection: $remindersTime, displayedComponents: .hourAndMinute, label: { CompatibleLabel(symbolName: "clock", text: "Time") })
                }
                .disabled(!remindersIsOn)
                Section {
                    Button(action: {}) {
                        HStack {
                            Text("Monday")
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                    Text("Tuesday")
                    Text("Wednesday")
                    Text("Thursday")
                    Text("Friday")
                    Text("Saturday")
                    Text("Sunday")
                }
                .disabled(!remindersIsOn)
            }
            .navigationBarTitle("Reminders")
            .navigationBarBackButtonHidden(false)
            .navigationBarItems(trailing: Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/) {
                Text("Done")
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct RemindersView_Previews: PreviewProvider {
    static var previews: some View {
        RemindersView(remindersIsOn: true, remindersTime: Date())
    }
}


