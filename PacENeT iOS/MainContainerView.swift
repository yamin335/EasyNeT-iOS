//
//  MainContainerView.swift
//  Pace Cloud
//
//  Created by rgl on 1/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct MainContainerView: View {
    
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack {
            if userData.isLoggedIn {
                MainScreen()
            } else {
                SplashAndLoginContainer()
            }
        }
    }
}

struct MainContainerView_Previews: PreviewProvider {
    static var previews: some View {
        MainContainerView()
            .environmentObject(UserData())
    }
}
