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
    @State private var disableSaveButton = true
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
                self.userData.isLoggedIn = false
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var changePasswordModal: some View {
        ZStack {
            Color.black
                .blur(radius: 0.5, opaque: false)
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading) {
                Text("Change Password")
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .foregroundColor(Colors.color2)
                    .padding(.leading, 20).padding(.trailing, 20).padding(.top, 8)
                SecureField("Old Password", text: $viewModel.oldPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 20).padding(.trailing, 20)
                SecureField("New Password", text: $viewModel.newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 20).padding(.trailing, 20).padding(.top, 8)
                SecureField("Confirm Password", text: $viewModel.newConfPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 20).padding(.trailing, 20).padding(.top, 8)
                HStack(alignment: .center, spacing: 20) {
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            self.showChangePassModal = false
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
                    }.disabled(disableSaveButton)
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }.frame(minWidth: 0, maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 6, style: .circular).fill(Color.white))
                .padding(.leading, 25)
                .padding(.trailing, 25)
        }
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Form {
                    Section(header: Text("General Settings")) {
                        Button(action: {
                            withAnimation {
                                self.showChangePassModal.toggle()
                            }
                        }) {
                            Text("Change Password").foregroundColor(.black)
                        }
                    }
                }.navigationBarTitle(Text("More"))
                    .navigationBarItems(trailing: signoutButton)
                
                if showChangePassModal {
                    changePasswordModal.edgesIgnoringSafeArea(.all)
                        .onReceive(self.viewModel.isChangePassFormValid.receive(on: RunLoop.main)) { isDisabled in
                        self.disableSaveButton = isDisabled
                    }
                }
                
            }
        }
    }
}

struct MoreMenu_Previews: PreviewProvider {
    static var previews: some View {
        MoreMenu().environmentObject(UserData())
    }
}
