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
    @ObservedObject var loginViewModel: LoginViewModel
    
    var body: some View {
        ZStack{
            LoginScreen(loginViewModel: loginViewModel)
            SplashScreen()
                .opacity(self.userData.shouldShowSplash ? 1 : 0)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation() {
                            self.userData.shouldShowSplash = false
                        }
                    }
                }
        }
    }
}

struct SplashAndLoginContainer_Previews: PreviewProvider {
    static var previews: some View {
        SplashAndLoginContainer(loginViewModel: LoginViewModel())
            .environmentObject(UserData())
    }
}
