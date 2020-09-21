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
    @ObservedObject var pgwViewModel = PGWViewModel()
    @State private var showSignoutAlert = false
    @State private var name = ""
    @State private var createDate = ""
    @State private var package = ""
    @State private var packageCharge = ""
    @State private var email = ""
    @State private var phone = ""
    @State var changingUserPackService: UserPackService?
    @State private var showLoader = false
    
    // Toasts
    @State var showSuccessToast = false
    @State var successMessage: String = ""
    @State var showWarningToast = false
    @State var warningMessage: String = ""
    @State var showErrorToast = false
    @State var errorMessage: String = ""
    
    @State var showPaymentOptionsModal = false
    @State var showChoiseBackGround = false
    
    @State var showPGW = false
    @State var pgw: PGW = .BKASH
    
    var background: some View {
        VStack {
            Rectangle().background(Color.black).blur(radius: 0.5, opaque: false).opacity(0.3)
        }
        .transition(.asymmetric(insertion: .opacity, removal: .opacity)).animation(.default)
        .zIndex(1)
    }
    
    var modalHeader: some View {
        VStack {
            HStack {
                Text("Pay With")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(Colors.color2)
                Spacer()
                Button(action: {
                    withAnimation {
                        self.showPaymentOptionsModal = false
                        self.showChoiseBackGround = false
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 16)
            .padding(.leading, 20)
            .padding(.trailing, 20)
        }.background(Color.white.opacity(0))
    }
    
    var modalOptions: some View {
        VStack(alignment: .leading, spacing: 0) {
//            Text("Debit/Credit Cards")
//                .font(.headline)
//                .foregroundColor(Colors.color2).padding(.top, 8)
//            
//            HStack {
//                Spacer()
//                Image("visa_card_logo")
//                .resizable()
//                .frame(width: 250, height: 90)
//                .scaledToFit()
//                .overlay (
//                    RoundedRectangle(cornerRadius: 4, style: .circular)
//                        .stroke(Color.gray, lineWidth: 0.5)
//                ).onTapGesture {
//                    guard let payAmount = self.viewModel.packChangeHelper?.payAmount, payAmount > 0, let userPackServiceId = self.viewModel.changingUserPackService?.userPackServiceId else {
//                        self.viewModel.errorToastPublisher.send((true, "Invalid Amount!"))
//                        return
//                    }
//                    self.pgwViewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: payAmount, deductedAmount: 0.0, invoiceId: 0, userPackServiceId: userPackServiceId, canModify: true, isChildInvoice: false)
//                    self.pgwViewModel.getFosterPaymentUrl()
//                    withAnimation {
//                        self.showPaymentOptionsModal = false
//                        self.showChoiseBackGround = false
//                    }
//                }
//                Spacer()
//            }.padding(.top, 6)
            
            Text("Bkash Mobile Banking")
                .font(.headline)
                .foregroundColor(Colors.color2)
                .padding(.top, 24)
            
            HStack {
                Spacer()
                Image("bkash_logo")
                .resizable()
                .frame(width: 250, height: 90)
                .scaledToFit()
                .overlay (
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .stroke(Color.gray, lineWidth: 0.5)
                ).onTapGesture {
                    guard let payAmount = self.viewModel.packChangeHelper?.payAmount, payAmount > 0, let userPackServiceId = self.viewModel.changingUserPackService?.userPackServiceId else {
                        self.viewModel.errorToastPublisher.send((true, "Invalid Amount!"))
                        return
                    }
                    self.pgwViewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: payAmount, deductedAmount: 0.0, invoiceId: 0, userPackServiceId: userPackServiceId, canModify: true, isChildInvoice: false)
                    self.pgwViewModel.getBkashToken()
                    withAnimation {
                        self.showPaymentOptionsModal = false
                        self.showChoiseBackGround = false
                    }
                }
                Spacer()
            }.padding(.top, 6)
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .padding(.top, 8)
    }
    
    var amountView: some View {
        HStack {
            Text("Bill Amount:")
                .font(.headline)
                .foregroundColor(Colors.color2)
                .padding(.leading, 20)
            
            Text("\(viewModel.packChangeHelper?.payAmount.rounded(toPlaces: 2) ?? "0.0") BDT")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Colors.color2)
                .padding(.trailing, 20)
            
            Spacer()
        }
    }
    
    var paymentOptionsModal: some View {
        VStack(alignment: .leading) {
            Spacer()
            VStack(alignment: .leading) {
                modalHeader
                Divider().padding(.bottom, 10)
                amountView
                modalOptions
            }
            .padding(.bottom, 30)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(ChatBubble(fillColor: Color.white, topLeft: 10, topRight: 10, bottomLeft: 0, bottomRight: 0))
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onAppear {
            withAnimation {
                self.showChoiseBackGround = true
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom))).animation(.default)
        .zIndex(2)
    }
    
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
    
    var profileImage: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 96, height: 96)
            .overlay(
            Image("profile_avater")
                .resizable()
                .frame(width: 65, height: 65)).shadow(radius: 5)
    }
    
    var coverImage: some View {
        Image("profile_cover")
        .resizable().frame(minWidth: 0, maxWidth: .infinity, maxHeight: 130)
        
    }
    
    var balanceView: some View {
        HStack(alignment: .center) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 17, weight: .regular))
                .imageScale(.large)
                .padding(.trailing, 5)
                .foregroundColor(Colors.color2)
            
            Text("Balance")
                .bold()
                .font(.system(size: 17))
                .font(.title)
                .foregroundColor(Colors.color2)
            
            Spacer()
            
            Text(viewModel.balance)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color.gray)
        }.padding(.bottom, 10)
    }
    
    var dueView: some View {
        HStack(alignment: .center) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.system(size: 17, weight: .regular))
                .imageScale(.large)
                .padding(.trailing, 5)
                .foregroundColor(Colors.color2)
            
            Text("Due")
                .bold()
                .font(.system(size: 17))
                .font(.title)
                .foregroundColor(Colors.color2)
            
            Spacer()
            
            Text(viewModel.due)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color.gray)
        }.padding(.bottom, 10)
    }
    
    var createView: some View {
        HStack(alignment: .center) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 17, weight: .regular))
                .imageScale(.large)
                .padding(.trailing, 5)
                .foregroundColor(Colors.color2)
            
            Text("Created On")
                .bold()
                .font(.system(size: 17))
                .font(.title)
                .foregroundColor(Colors.color2)
            
            Spacer()
            
            Text(createDate)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color.gray)
        }.padding(.bottom, 10)
    }
    
    var chargeView: some View {
        HStack(alignment: .center) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 17, weight: .regular))
                .imageScale(.large)
                .padding(.trailing, 5)
                .foregroundColor(Colors.color2)
            
            Text("Monthly Charge")
                .bold()
                .font(.system(size: 17))
                .font(.title)
                .foregroundColor(Colors.color2)
            
            Spacer()
            
            Text(packageCharge + " (BDT)")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color.gray)
        }.padding(.bottom, 10)
    }
    
    var emailView: some View {
        HStack(alignment: .center) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 17, weight: .regular))
                .imageScale(.large)
                .padding(.trailing, 5)
                .foregroundColor(Colors.color2)
            
            Text("Email")
                .bold()
                .font(.system(size: 17))
                .font(.title)
                .foregroundColor(Colors.color2)
            
            Spacer()
            
            Text(email)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color.gray)
        }.padding(.bottom, 10)
    }
    
    var phoneView: some View {
        HStack(alignment: .center) {
            Image(systemName: "phone.fill")
                .font(.system(size: 17, weight: .regular))
                .imageScale(.large)
                .padding(.trailing, 5)
                .foregroundColor(Colors.color2)
            
            Text("Phone")
                .bold()
                .font(.system(size: 17))
                .font(.title)
                .foregroundColor(Colors.color2)
            
            Spacer()
            
            Text(phone)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color.gray)
        }.padding(.bottom, 10)
    }
    
    var body: some View {
        
        NavigationView {
            ZStack {
                VStack(alignment: .center, spacing: 0) {
                    coverImage
                    
                    profileImage.offset(y: -70)
                    .padding(.bottom, -70)
                    
                    Text(name)
                        .font(.system(size: 24))
                        .fontWeight(.heavy)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .foregroundColor(Colors.color2)
                    
                    Group {
                        balanceView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 5)
                        Divider().padding(.leading, 16)
                        dueView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                        Divider().padding(.leading, 16)
                        createView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                        Divider().padding(.leading, 16)
                        emailView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                        Divider().padding(.leading, 16)
                        phoneView.padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                        Divider().padding(.leading, 16)
                    }
                    
                    HStack {
                        Text("SERVICES")
                        .font(.system(size: 20))
                        .fontWeight(.heavy)
                        .padding(.top, 20)
                        .padding(.leading, 16)
                        .padding(.trailing, 16)
                        .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    VStack {
                        List(self.viewModel.userPackServices, id: \.userPackServiceId) { dataItem in
                            PackServiceRowView(item: dataItem, viewModel: self.viewModel)
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
                    .onReceive(self.pgwViewModel.showLoader.receive(on: RunLoop.main)) { shouldShow in
                        self.showLoader = shouldShow
                    }
                    .onReceive(self.pgwViewModel.warningToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                        self.showWarningToast = shouldShow
                        self.warningMessage = message
                    }
                    .onReceive(self.pgwViewModel.errorToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                        self.showErrorToast = shouldShow
                        self.errorMessage = message
                    }
                    .onReceive(self.pgwViewModel.successToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                        self.showSuccessToast = shouldShow
                        self.successMessage = message
                    }
                    .onReceive(self.viewModel.paymentOptionsModalPublisher.receive(on: RunLoop.main)) { shouldShow in
                        self.showPaymentOptionsModal = shouldShow
                    }
                    .onReceive(self.pgwViewModel.bkashPaymentStatusPublisher.receive(on: RunLoop.main)) { (isSuccessful, response) in
                        if isSuccessful {
                            self.viewModel.saveChangedPackByBkash(bkashResData: response!)
                        } else {
                            self.viewModel.errorToastPublisher.send((true, "Payment not successful, please try again later!"))
                        }
                    }
                    .onReceive(self.pgwViewModel.fosterPaymentStatusPublisher.receive(on: RunLoop.main)) { (isSuccessful, response) in
                        if isSuccessful {
                            self.viewModel.saveChangedPackByFoster(fosterModel: response)
                        } else {
                            self.viewModel.errorToastPublisher.send((true, "Payment not successful, please try again later!"))
                        }
                    }
                }
                .onReceive(self.viewModel.showServiceChangeModal.receive(on: RunLoop.main)) { (boolData, packService) in
                    if packService.packServiceTypeId == 1 {
                        self.changingUserPackService = packService
                        self.isPackageSheetPresented = boolData
                    }
                }
                .onReceive(self.pgwViewModel.showPGW.receive(on: RunLoop.main)) { (shouldShow, pgw) in
                    self.pgw = pgw
                    self.showPGW = shouldShow
                }
                .onAppear() {
                    self.prepareProfileData()
                    self.viewModel.refreshUI()
                }
                .background(Color.white).navigationBarTitle(Text("Profile"))
                    .navigationBarItems(leading: refreshButton)
                
                if self.showChoiseBackGround {
                    self.background
                }
                
                if self.showPaymentOptionsModal {
                    self.paymentOptionsModal
                }
                
                if showPGW {
                    PGWView(viewModel: pgwViewModel, pgw: pgw)
                }
                
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
    }
    
    func prepareProfileData() {
        let userInfo = UserLocalStorage.getLoggedUserData()
        let nameData = userInfo?.displayName ?? ""
        self.name = nameData.isEmpty ? "No Name Provided" : nameData
        self.createDate = "\(userInfo?.created ?? "")"
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
