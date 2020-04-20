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
    @State private var balance = ""
    @State private var createDate = ""
    @State private var package = ""
    @State private var packageCharge = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var userPackServices = [UserPackService]()
    @State var changingUserPackService: UserPackService?
    
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
    
    var balanceView: some View {
        VStack(alignment: .leading) {
            Text("Balance")
                .bold()
                .font(.system(size: 15))
                .font(.title)
                .foregroundColor(Color.gray)
            Text(balance + " BDT")
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
            VStack(spacing: 0) {
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
                balanceView
                createView
                emailView
                phoneView
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
            .background(Color.white).navigationBarTitle(Text("Profile"), displayMode: .inline)
                .navigationBarItems(leading: refreshButton, trailing: signoutButton)
        }
        .sheet(isPresented: $isPackageSheetPresented, onDismiss: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.viewModel.getUserPackServiceData()
            }
        }, content: {
            PackageChangeView(viewModel: self.viewModel, changingUserPackService: self.changingUserPackService!)
        })
        .onAppear() {
            let months = [0 : "", 1 : "Jan", 2 : "Feb", 3 : "Mar", 4 : "Apr", 5 : "May", 6 : "Jun", 7 : "Jul", 8 : "Aug", 9 : "Sep", 10 : "Oct", 11 : "Nov", 12 : "Dec"]
            let userInfo = UserLocalStorage.getLoggedUserData()
            let nameData = userInfo?.displayName ?? ""
            self.name = nameData.isEmpty ? "No Name Provided" : nameData
            let date = userInfo?.created ?? ""
            if date.contains("T") {
                let splits = date.split(separator: "T")

                let tempSplits = (splits.count > 1 ? splits[1] : "").split(separator: ".")[0].split(separator: ":")
                let dateSplits = splits[0].split(separator: "-")
                self.createDate = "Date: \(dateSplits[2])\(months[Int(dateSplits[1]) ?? 0] ?? ""), \(dateSplits[0]) & Time: \(tempSplits[0]):\(tempSplits[1])"
            } else {
                self.createDate = userInfo?.created ?? ""
            }
            
            self.balance = String(userInfo?.balance ?? 0.0)
            self.package = userInfo?.srvName ?? ""
            self.packageCharge = String(userInfo?.unitPrice ?? 0.0)
            let emailData = userInfo?.email ?? ""
            self.email = emailData.isEmpty ? "N/A" : emailData
            let phoneData = userInfo?.phone ?? ""
            self.phone = phoneData.isEmpty ? "N/A" : phoneData
        }
    }
}

extension String {
    func formatDate() -> String {
        let months = [0 : "", 1 : "Jan", 2 : "Feb", 3 : "Mar", 4 : "Apr", 5 : "May", 6 : "Jun", 7 : "Jul", 8 : "Aug", 9 : "Sep", 10 : "Oct", 11 : "Nov", 12 : "Dec"]
        if self.contains("T") {
            let splits = self.split(separator: "T")

            let tempSplits = (splits.count > 1 ? splits[0] : "").split(separator: "-")

            return "\(tempSplits[2]) \(months[Int(tempSplits[1]) ?? 0] ?? ""), \(tempSplits[0])"
        } else {
            let tempSplits = self.split(separator: "-")

            return "\(tempSplits[2]) \(months[Int(tempSplits[1]) ?? 0] ?? ""), \(tempSplits[0])"
        }
    }
}

extension String {
    func formatTime() -> String {
        if self.contains("T") {
            let tempStringArray = self.split(separator: "T")
            var tempString1 = tempStringArray[1]
            var hour = 0
            var minute = 0
            var seconds = 0
            var amPm = ""
            if (tempString1.contains(".")){
                tempString1 = tempString1.split(separator: ".")[0]
                hour = Int(tempString1.split(separator: ":")[0]) ?? 0
                minute = Int(tempString1.split(separator: ":")[1]) ?? 0
                seconds = Int(tempString1.split(separator: ":")[2]) ?? 0
                amPm = ""
                if hour > 12 {
                    hour -= 12
                    amPm = "PM"
                } else if hour == 0 {
                    hour += 12
                    amPm = "AM"
                } else if hour == 12 {
                    amPm = "PM"
                } else {
                    amPm = "AM"
                }
            } else {
                hour = Int(tempString1.split(separator: ":")[0]) ?? 0
                minute = Int(tempString1.split(separator: ":")[1]) ?? 0
                seconds = Int(tempString1.split(separator: ":")[2]) ?? 0
                amPm = ""
                if hour > 12 {
                    hour -= 12
                    amPm = "PM"
                } else if hour == 0 {
                    hour += 12
                    amPm = "AM"
                } else if hour == 12 {
                    amPm = "PM"
                } else {
                    amPm = "AM"
                }
            }
            return "\(hour):\(minute) \(amPm)"
        }
        return ""
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
