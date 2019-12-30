//
//  MainScreen.swift
//  Pace Cloud
//
//  Created by rgl on 1/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct MainScreen: View {
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection){
            Dashboard()
                .tabItem {
                VStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                    Text("Dashboard")
                }
            }
            .tag(0)
            
            Profile()
                .tabItem {
                VStack {
                    Image(systemName: "person")
                        .imageScale(.large)
                    Text("Profile")
                }
            }
            .tag(1)
            
            Billing()
                .tabItem {
                    VStack {
                        Image(systemName: "chart.bar")
                            .imageScale(.large)
                        Text("Billing")
                    }
            }
            .tag(2)
            
            Support()
                .tabItem {
                    VStack {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                        Text("Support")
                    }
            }
            .tag(3)
            
            MoreMenu()
                .tabItem {
                    VStack {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                        Text("More")
                    }
            }
            .tag(4)
        }.accentColor(Colors.greenTheme)
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
            .environmentObject(UserData())
    }
}
