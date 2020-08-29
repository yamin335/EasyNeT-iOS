//
//  SplashAndLoginContainer.swift
//  Pace Cloud
//
//  Created by rgl on 30/9/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct SplashAndLoginContainer: View {
    
    @EnvironmentObject var userData: UserData
    
    init() {
        // For navigation bar background color
        UINavigationBar.appearance().barTintColor = nil
        UINavigationBar.appearance().backgroundColor = nil
    }
    
    var body: some View {
        ZStack{
            LoginScreen()
            SplashScreen()
                .opacity(self.userData.shouldShowSplash ? 1 : 0)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation() {
                            if UserLocalStorage.isLoggedIn() {
                                self.userData.isLoggedIn = true
                            }
                            self.userData.shouldShowSplash = false
                        }
                    }
                }
        }
    }
}

struct SplashAndLoginContainer_Previews: PreviewProvider {
    static var previews: some View {
        SplashAndLoginContainer()
            .environmentObject(UserData())
    }
}
