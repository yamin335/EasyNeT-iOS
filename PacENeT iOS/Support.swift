//
//  Support.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct Support: View {
    
    @EnvironmentObject var userData: UserData
    @State private var showSignoutAlert = false
    
    var signoutButton: some View {
        Button(action: {
            self.showSignoutAlert = true
        }) {
            Text("Sign Out")
                .foregroundColor(Colors.greenTheme)
        }
        .alert(isPresented:$showSignoutAlert) {
            Alert(title: Text("Sign Out"), message: Text("Are you sure to sign out?"), primaryButton: .destructive(Text("Yes")) {
                self.userData.isLoggedIn = false
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var refreshButton: some View {
        Button(action: {
            //            self.viewModel.refreshUI()
            
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .light))
                .imageScale(.large)
                .accessibility(label: Text("Refresh"))
                .padding()
                .foregroundColor(Colors.greenTheme)
            
        }
    }
    
    var body: some View {
        
        NavigationView {
            VStack {
                Text("Support")
            }.navigationBarTitle(Text("Support"), displayMode: .inline)
                .navigationBarItems(leading: refreshButton, trailing: signoutButton)
        }
    }
}

struct Support_Previews: PreviewProvider {
    static var previews: some View {
        Support().environmentObject(UserData())
    }
}
