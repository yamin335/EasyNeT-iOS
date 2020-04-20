//
//  UITestView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/3/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct UITestView: View {
    
    @State var nameEditMode = false
    @State var name = "Mr. Foo Bar"
    @State var listItems = [String]()
    
    init() {
        UITableView.appearance().tableFooterView = UIView()
        UITableView.appearance().separatorStyle = .none
    }
    
    func createListItems() {
        var list = [String]()
        for i in 1...50 {
            list.append("Item-No-\(i)")
        }
        listItems = list
        listItems.reverse()
    }
    
    var row: some View {
        HStack {
            Image(systemName: "person.circle").resizable().frame(width: 30, height: 30)
            
            if nameEditMode {
                TextField("Name", text: $name).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.leading, 5).font(.system(size: 20))
                .autocapitalization(.words)
                .disableAutocorrection(true)
            } else {
                Text(name).font(.system(size: 20))
            }
            
            Button(action: {
                self.nameEditMode.toggle()
            }) {
                Text(nameEditMode ? "Done" : "Edit").font(.system(size: 20)).fontWeight(.light)
                    .foregroundColor(Color.blue)
            }
        }
    }
    
    var changeButton: some View {
        Button(action: {
            withAnimation {
                self.listItems.append("New Items")
            }
        }) {
            HStack(spacing: 2) {
                Text("Change").foregroundColor(Colors.color7).padding(.trailing, 3)
            }
            .padding(.trailing, 8)
            .padding(.leading, 10)
            .padding(.top, 4)
            .padding(.bottom, 4)
            .overlay (
                RoundedRectangle(cornerRadius: 4, style: .circular)
                    .stroke(Color.gray, lineWidth: 0.5)
            )
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            VStack(alignment: .leading, spacing: 3) {
                List(listItems, id: \.self) { item in
                    Text(item).scaleEffect(x: 1, y: -1, anchor: .center)
                }.scaleEffect(x: 1, y: -1, anchor: .center)
                .onAppear {
                    self.createListItems()
                }
                row
                HStack {
                    Text("10 Mbps-standard pack").font(.title)
                    Circle()
                        .frame(width: 18, height: 18)
                        .foregroundColor(Colors.greenTheme)
                        .padding(.all, 1)
                }
                
                Text("Price:  900.00 BDT").foregroundColor(.gray)
                Text("Active:  9-2-2020  to  9-3-2020").foregroundColor(.gray)
            }
            Spacer()
            changeButton
        }.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8).padding(.bottom, 10)
    }
}

struct UITestView_Previews: PreviewProvider {
    static var previews: some View {
        UITestView()
    }
}
