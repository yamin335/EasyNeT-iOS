//
//  Profile.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct Profile: View {
    
    @EnvironmentObject var userData: UserData
    @State private var showSignoutAlert = false
    @State private var name = ""
    @State private var balance = ""
    @State private var createDate = ""
    @State private var package = ""
    @State private var packageCharge = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isPackageSheetPresented = false
    
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
    
    var profileHeader: some View {
        Colors.color5.overlay( HStack {
            VStack {
                Circle().fill(Color.white)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Image("profile_avater")
                            .resizable()
                            .frame(width: 65, height: 65))
                
                Text(name)
                    .bold()
                    .font(.system(size: 18))
                    .font(.title)
                    .foregroundColor(Colors.color6)
                Spacer()
                }.padding(.top, 24)
        }).frame(minWidth: 0, maxWidth: .infinity, maxHeight: 175)
    }
    
    var balanceView: some View {
        VStack(alignment: .leading) {
            Text("Balance")
                .bold()
                .font(.system(size: 15))
                .font(.title)
                .foregroundColor(Color.gray)
            Text(balance + " (BDT)")
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }.padding(.leading, 16)
    }
    
    var createView: some View {
        VStack(alignment: .leading) {
            Text("Created On")
                .bold()
                .font(.system(size: 15))
                .font(.title)
                .foregroundColor(Color.gray)
            Text(createDate)
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }.padding(.leading, 16)
    }
    
    struct PackageChangeView: View {
        @Environment(\.presentationMode) var presentationMode
        var body: some View {
            NavigationView {
                Text("Package Change View")
                .navigationBarTitle(Text("Sheet View"), displayMode: .inline)
                    .navigationBarItems(trailing: Button(action: {
                        print("Dismissing sheet view...")
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done").bold()
                    })
            }
        }
    }
    
    var packageView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Package")
                    .bold()
                    .font(.system(size: 15))
                    .font(.title)
                    .foregroundColor(Color.gray)
                
                Button(action: {
                    self.isPackageSheetPresented.toggle()
                }) {
                    Text("Change")
                        .foregroundColor(Colors.color7)
                }.sheet(isPresented: $isPackageSheetPresented, content: {
                    PackageChangeView()
                })
            }
            Text(package)
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }.padding(.leading, 16)
    }
    
    var chargeView: some View {
        VStack(alignment: .leading) {
            Text("Monthly Charge")
                .bold()
                .font(.system(size: 15))
                .font(.title)
                .foregroundColor(Color.gray)
            Text(packageCharge + " (BDT)")
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }.padding(.leading, 16)
    }
    
    var emailView: some View {
        VStack(alignment: .leading) {
            Text("Email")
                .bold()
                .font(.system(size: 15))
                .font(.title)
                .foregroundColor(Color.gray)
            Text(email)
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }.padding(.leading, 16)
    }
    
    var phoneView: some View {
        VStack(alignment: .leading) {
            Text("Phone")
                .bold()
                .font(.system(size: 15))
                .font(.title)
                .foregroundColor(Color.gray)
            Text(phone)
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }.padding(.leading, 16)
    }
    
    var body: some View {
        
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                profileHeader
                balanceView
                createView
                packageView
                chargeView
                emailView
                phoneView
                Spacer()
            }.background(Color.white).navigationBarTitle(Text("Profile"), displayMode: .inline)
                .navigationBarItems(leading: refreshButton, trailing: signoutButton)
        }.onAppear() {
            let userInfo = UserLocalStorage.getLoggedUserData()
            self.name = userInfo?.displayName ?? ""
            let date = userInfo?.created ?? ""
            if date.contains("T") {
                let splits = date.split(separator: "T")

                let tempSplits = (splits.count > 1 ? splits[1] : "").split(separator: ".")[0].split(separator: ":")

                self.createDate = splits[0] + "  " + tempSplits[0] + ":" + tempSplits[1]
            } else {
                self.createDate = userInfo?.created ?? ""
            }
            
            self.balance = String(userInfo?.balance ?? 0.0)
            self.package = userInfo?.srvName ?? ""
            self.packageCharge = String(userInfo?.unitPrice ?? 0.0)
            self.email = userInfo?.email ?? ""
            self.phone = userInfo?.phone ?? ""
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile().environmentObject(UserData())
    }
}
