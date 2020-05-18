//
//  Profile.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct Profile: View {
    
    @State var isPackageSheetPresented = false
    @EnvironmentObject var userData: UserData
    @ObservedObject var viewModel = ProfileViewModel()
    @State private var showSignoutAlert = false
    @State private var name = ""
    @State private var createDate = ""
    @State private var package = ""
    @State private var packageCharge = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var userPackServices = [UserPackService]()
    @State var changingUserPackService: UserPackService?
    @State private var showLoader = false
    
    // Toasts
    @State var showSuccessToast = false
    @State var successMessage: String = ""
    @State var showWarningToast = false
    @State var warningMessage: String = ""
    @State var showErrorToast = false
    @State var errorMessage: String = ""
    
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
                self.userData.selectedTabItem = 0
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var refreshButton: some View {
        Button(action: {
            self.viewModel.refreshUI()
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
            Text(viewModel.balance)
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }
    }
    
    var dueView: some View {
        VStack(alignment: .leading) {
            Text("Due")
                .bold()
                .font(.system(size: 15))
                .font(.title)
                .foregroundColor(Color.gray)
            Text(viewModel.due)
                .font(.system(size: 14))
                .font(.body)
                .foregroundColor(Color.gray)
        }
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
        }
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
        }
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
        }
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
        }
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.system(size: 17))
                        .fontWeight(.heavy)
                        .padding(.top, 8)
                        .padding(.bottom, 6)
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .foregroundColor(.gray)
                    
                    balanceView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 5)
                    dueView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                    createView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                    emailView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                    phoneView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                    Text("Your Services")
                    .font(.system(size: 17))
                    .fontWeight(.heavy)
                    .padding(.top, 20)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    .foregroundColor(.gray)
                    List {
                        VStack {
                            ForEach(userPackServices, id: \.userPackServiceId) { dataItem in
                                VStack {
                                    PackServiceRowView(item: dataItem, viewModel: self.viewModel)
                                    if !self.viewModel.userPackServices.isLastUserPack(item: dataItem) {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .onReceive(self.viewModel.showLoader.receive(on: RunLoop.main)) { shouldShow in
                        self.showLoader = shouldShow
                    }
                    .onReceive(self.viewModel.warningToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                        self.showWarningToast = shouldShow
                        self.warningMessage = message
                    }
                    .onReceive(self.viewModel.errorToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                        self.showErrorToast = shouldShow
                        self.errorMessage = message
                    }
                    .onReceive(self.viewModel.successToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                        self.showSuccessToast = shouldShow
                        self.successMessage = message
                    }
                    .onReceive(self.viewModel.$userPackServices.receive(on: RunLoop.main)) {
                            userPackServices in
                        withAnimation {
                            self.userPackServices = userPackServices
                        }
                    }
                }
                .onReceive(self.viewModel.showServiceChangeModal.receive(on: RunLoop.main)) { (boolData, packService) in
                    self.changingUserPackService = packService
                    self.isPackageSheetPresented = boolData
                }
                .onAppear {
                    self.viewModel.getUserPackServiceData()
                    self.viewModel.getPackServiceData()
                }
                .background(Color.white).navigationBarTitle(Text("Profile"))
                    .navigationBarItems(leading: refreshButton)
                
                if self.showSuccessToast {
                    VStack {
                        Spacer()
                        SuccessToast(message: self.successMessage).onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation() {
                                    self.showSuccessToast = false
                                    self.successMessage = ""
                                }
                            }
                        }.padding(.all, 20)
                    }.zIndex(3)
                }

                if self.showErrorToast {
                    VStack {
                        Spacer()
                        ErrorToast(message: self.errorMessage).onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation() {
                                    self.showErrorToast = false
                                    self.errorMessage = ""
                                }
                            }
                        }.padding(.all, 20)
                    }.zIndex(3)
                }
                
                if self.showWarningToast {
                    VStack {
                        Spacer()
                        WarningToast(message: self.warningMessage).onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation() {
                                    self.showWarningToast = false
                                    self.warningMessage = ""
                                }
                            }
                        }.padding(.all, 20)
                    }.zIndex(3)
                }
                
                if self.showLoader {
                    SpinLoaderView().zIndex(4)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isPackageSheetPresented, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.viewModel.getUserPackServiceData()
            }
        }, content: {
            PackageChangeView(viewModel: self.viewModel, changingUserPackService: self.changingUserPackService!)
        })
        .onAppear() {
            self.prepareProfileData()
            self.viewModel.getUserBalance()
        }
    }
    
    func prepareProfileData() {
        let userInfo = UserLocalStorage.getLoggedUserData()
        let nameData = userInfo?.displayName ?? ""
        self.name = nameData.isEmpty ? "No Name Provided" : nameData
        self.createDate = "Date & Time: \(userInfo?.created?.formatDate() ?? "")  \(userInfo?.created?.formatTime() ?? "")"
        self.package = userInfo?.srvName ?? ""
        self.packageCharge = String(userInfo?.unitPrice ?? 0.0)
        let emailData = userInfo?.email ?? ""
        self.email = emailData.isEmpty ? "N/A" : emailData
        let phoneData = userInfo?.phone ?? ""
        self.phone = phoneData.isEmpty ? "N/A" : phoneData
    }
}

extension RandomAccessCollection where Self.Element == UserPackService {
    
    func isLastUserPack(item: UserPackService) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard let itemIndex = firstIndex(where: { $0.packServiceId == item.packServiceId }) else {
            return false
        }
        
        let distance = self.distance(from: itemIndex, to: endIndex)
        return distance == 1
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile().environmentObject(UserData())
    }
}
