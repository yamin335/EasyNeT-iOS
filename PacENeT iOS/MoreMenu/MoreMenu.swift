//
//  MoreMenu.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct MoreMenu: View {
    
    @EnvironmentObject var userData: UserData
    @State private var showSignoutAlert = false
    @State private var showChangePassModal = false
    @State private var showChoiceBackground = false
    @State private var showOldPassError = false
    @State private var showSamePassError = false
    @State private var showPassMisMatchError = false
    @State private var newPassErrorMessage = ""
    @State private var showLoader = false
    @State var showSuccessToast = false
    @State var successMessage: String = ""
    @State var showErrorToast = false
    @State var errorMessage: String = ""
    @State private var enableSaveButton = false
    @ObservedObject var viewModel = MoreMenuViewModel()
    
    var signoutButton: some View {
        Button(action: {
            self.showSignoutAlert = true
        }) {
            Text("Sign Out")
                .foregroundColor(Colors.greenTheme)
        }
        .alert(isPresented:$showSignoutAlert) {
            Alert(title: Text("Sign Out"), message: Text("Are you sure to sign out?"), primaryButton: .destructive(Text("Yes")) {
                self.signOut()
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var changePasswordModal: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Change Password")
                .font(.system(size: 24))
                .fontWeight(.light)
                .foregroundColor(Colors.color2)
                .padding(.leading, 20).padding(.trailing, 20).padding(.top, 8)
            SecureField("Old Password", text: $viewModel.oldPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 20).padding(.trailing, 20).padding(.top, 12)
            if showOldPassError {
                Text("Wrong Old Password!")
                    .font(.caption)
                    .fontWeight(.light)
                    .foregroundColor(Color.red)
                    .padding(.leading, 20).padding(.trailing, 20)
            }
            SecureField("New Password", text: $viewModel.newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 20).padding(.trailing, 20).padding(.top, 12)
            if showSamePassError {
                Text(newPassErrorMessage)
                    .font(.caption)
                    .fontWeight(.light)
                    .foregroundColor(Color.red)
                    .padding(.leading, 20).padding(.trailing, 20)
            }
            SecureField("Confirm Password", text: $viewModel.newConfPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.leading, 20).padding(.trailing, 20).padding(.top, 12)
            if showPassMisMatchError {
                Text("Password Mismatched!")
                    .font(.caption)
                    .fontWeight(.light)
                    .foregroundColor(Color.red)
                    .padding(.leading, 20).padding(.trailing, 20)
            }
            HStack(alignment: .center, spacing: 20) {
                Spacer()
                
                Button(action: {
                    withAnimation {
                        self.showChangePassModal = false
                        self.showChoiceBackground = false
                        self.clearTextFields()
                    }
                }) {
                    Text("Close")
                        .fontWeight(.light)
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .foregroundColor(.red)
                        .background(RoundedRectangle(cornerRadius: 4, style: .circular).fill(Colors.whiteGray))
                }
                
                Button(action: {
                    withAnimation {
                        self.showChangePassModal = false
                        self.showChoiceBackground = false
                        self.clearTextFields()
                        //self.viewModel.changePassword()
                        self.viewModel.errorToastPublisher.send((true, "You are not allowed to change the password!"))
                    }
                }) {
                    Text("Save")
                        .fontWeight(.light)
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .foregroundColor(Colors.greenTheme)
                        .background(RoundedRectangle(cornerRadius: 4, style: .circular).fill(Colors.whiteGray))
                }.disabled(!enableSaveButton)
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 6, style: .circular).fill(Color.white))
        .padding(.leading, 25)
        .padding(.trailing, 25)
        .zIndex(2)
        .onAppear {
            withAnimation {
                self.showChoiceBackground = true
            }
        }
        .transition(.asymmetric(insertion: .opacity, removal: .opacity)).animation(.default)
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Form {
//                    Section(header: Text("General Settings")) {
//                        Button(action: {
//                            withAnimation {
//                                self.showChangePassModal.toggle()
//                            }
//                        }) {
//                            Text("Change Password").foregroundColor(.black)
//                        }
//                    }
                    Section {
                        NavigationLink(destination: PrivacyView()) {
                            Text("Privacy Policy")
                        }
                    }
                }.navigationBarTitle(Text("More"))
                    .navigationBarItems(trailing: signoutButton)
                
                if showChoiceBackground {
                    VStack {
                        Rectangle().background(Color.black).blur(radius: 0.5, opaque: false).opacity(0.3)
                    }
                    .zIndex(1)
                    .transition(.asymmetric(insertion: .opacity, removal: .opacity)).animation(.default)
                    .onTapGesture {
                        withAnimation {
                            self.showChangePassModal = false
                            self.showChoiceBackground = false
                        }
                    }
                }
                
                if showChangePassModal {
                    changePasswordModal.edgesIgnoringSafeArea(.all)
                        .onReceive(self.viewModel.isChangePassFormValid.receive(on: RunLoop.main)) { value in
                            self.showOldPassError = value == 1
                            if value == 2 {
                                self.showSamePassError = true
                                self.newPassErrorMessage = "Same as Old Password!"
                            } else if value == 3 {
                                self.showSamePassError = true
                                self.newPassErrorMessage = "Password length must range from 5 to 24"
                            } else {
                                self.showSamePassError = false
                                self.newPassErrorMessage = ""
                            }
                            self.showPassMisMatchError = value == 4
                            self.enableSaveButton = value == 5
                    }
                }
                
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
            .onReceive(self.viewModel.showLoader.receive(on: RunLoop.main)) { doingSomethingNow in
                self.showLoader = doingSomethingNow
            }
            .onReceive(self.viewModel.successToastPublisher.receive(on: RunLoop.main)) {
                showToast, message in
                self.successMessage = message
                withAnimation() {
                    self.showSuccessToast = showToast
                }
            }
            .onReceive(self.viewModel.errorToastPublisher.receive(on: RunLoop.main)) {
                showToast, message in
                self.errorMessage = message
                withAnimation() {
                    self.showErrorToast = showToast
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    func clearTextFields() {
        self.viewModel.oldPassword = ""
        self.viewModel.newPassword = ""
        self.viewModel.newConfPassword = ""
    }
    
    func signOut() {
        UserLocalStorage.clearLoggedUserData()
        UserLocalStorage.clearUserCredentials()
        UserLocalStorage.setUserSignedIn(isLoggedin: false)
        self.userData.isLoggedIn = false
        self.userData.selectedTabItem = 0
    }
}

struct MoreMenu_Previews: PreviewProvider {
    static var previews: some View {
        MoreMenu().environmentObject(UserData())
    }
}
