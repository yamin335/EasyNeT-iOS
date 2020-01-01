//
//  LoginScreen.swift
//  Pace Cloud
//
//  Created by rgl on 30/9/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI
import Combine
struct LoginScreen: View {
    
    @EnvironmentObject var userData: UserData
    @ObservedObject var loginViewModel = LoginViewModel()
    @State private var showLoader = false
    @State private var loginStatusSubscriber: AnyCancellable? = nil
//    @State var showSignUpModal = false
    
    @State private var loginButtonDisabled = true
    
    //Login toasts
    @State var showSuccessToast = false
    @State var successMessage: String = ""
    @State var showErrorToast = false
    @State var errorMessage: String = ""
    
    var contentView: some View {
        VStack(alignment: .center) {
            Image("pace_net")
                .resizable()
                .frame(width: 120, height: 120)
            
            TextField("Username", text: $loginViewModel.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 20).padding(.trailing, 20).padding(.top, 20)
            
            SecureField("Password", text: $loginViewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 20).padding(.trailing, 20).padding(.top, 8)
            HStack{
                Button(action: {
                    self.loginViewModel.doLogIn()
                }) {
                    HStack{
                        Spacer()
                        Text("Sign In").foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Colors.greenTheme)
                    .cornerRadius(2)
                }
                .disabled(loginButtonDisabled)
                .onReceive(self.loginViewModel.validatedCredentials) { validCredential in
                    self.loginButtonDisabled = !validCredential
                }
                .onReceive(self.loginViewModel.loginStatusPublisher.receive(on: RunLoop.main)) { isLoggedIn in
                    self.userData.isLoggedIn = isLoggedIn
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.top, 8)
        }
    }
 
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .center) {
                    contentView
                    Button(action: {
                        //
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(Colors.greenTheme)
                            .padding(.top, 2)
                    }
                    
                    HStack(alignment: .center){
                        Text("Don't have an account yet?")
                            .foregroundColor(.gray).font(.subheadline)
                        
                        Button(action: {
                            withAnimation() {
//                                self.loginViewModel.showSignupModal = true
                            }
                        }) {
                            Text("Sign Up")
                                .foregroundColor(Colors.greenTheme)
                        }
                    }
                    .padding(.top, 1)
                    Spacer()
                    HStack(alignment: .center){
                        
                        NavigationLink(destination: FaqsView()) {
                            Text("FAQs")
                                .foregroundColor(Colors.greenTheme)
                                .font(.subheadline)
                        }
                        
                        Divider().frame(width: 1, height: 14, alignment: .center)
                            .background(Colors.greenTheme)
                        
                        NavigationLink(destination: PrivacyView()) {
                            Text("Privacy")
                                .foregroundColor(Colors.greenTheme)
                                .font(.subheadline)
                        }
                        
                        Divider().frame(width: 1, height: 14, alignment: .center)
                            .background(Colors.greenTheme)
                        
                        NavigationLink(destination: ContactView()) {
                            Text("Contact")
                                .foregroundColor(Colors.greenTheme)
                                .font(.subheadline)
                        }
                    }
                    .padding(.top, 1)
                    .padding(.bottom, 16)
                    
                    Text("All rights reserved. Copyright ©2019, Royal Green Ltd.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                    
                }
//                .onReceive(self.loginViewModel.signUpModalValuePublisher.receive(on: RunLoop.main)) { value in
//                    self.showSignUpModal = value
//                }

//                
//                if self.showSignUpModal {
////                    SignupView(loginViewModel: loginViewModel).edgesIgnoringSafeArea(.all)
//                }
                
                if self.showSuccessToast {
                    SuccessToast(message: self.successMessage).onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation() {
                                self.showSuccessToast = false
                                self.successMessage = ""
                            }
                        }
                    }
                }

                if showErrorToast {
                    ErrorToast(message: self.errorMessage).onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation() {
                                self.showErrorToast = false
                                self.errorMessage = ""
                            }
                        }
                    }
                }

                if showLoader {
                    SpinLoaderView()
                }
                
            }
            .onReceive(self.loginViewModel.showLoginLoader.receive(on: RunLoop.main)) { doingSomethingNow in
                self.showLoader = doingSomethingNow
            }
            .onReceive(self.loginViewModel.successToastPublisher.receive(on: RunLoop.main)) {
                showToast, message in
                self.successMessage = message
                withAnimation() {
                    self.showSuccessToast = showToast
                }
            }
            .onReceive(self.loginViewModel.errorToastPublisher.receive(on: RunLoop.main)) {
                showToast, message in
                self.errorMessage = message
                withAnimation() {
                    self.showErrorToast = showToast
                }
            }
        }
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
            .environmentObject(UserData())
    }
}
