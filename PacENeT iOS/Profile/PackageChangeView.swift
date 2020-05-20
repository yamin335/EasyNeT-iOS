//
//  PackageChangeView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/4/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct PackageChangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProfileViewModel
    @State var changingUserPackService: UserPackService
    @State var showingPopup = false
    @State var selectedPackService: ChildPackService
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
    @State var payableAmount = ""
    @State var selectedPayMethod = 0
    
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
                Text("Additional payment for \(selectedPackService.packServiceName ?? "")")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(Colors.color2)
                    .lineLimit(3)
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
            .padding(.leading, 16)
            .padding(.trailing, 16)
        }.background(Color.white.opacity(0))
    }
    
    var payNow: some View {
        HStack {
            Spacer()
            Button(action: {
                guard let payable = Double(self.payableAmount), payable > 0, let payAmount = self.viewModel.packChangeHelper?.payAmount, payable == payAmount else {
                    self.viewModel.warningToastPublisher.send((true, "Please enter required amount!!"))
                    return
                }
                
                self.viewModel.dismissPackageChangeModal.send(true)
                self.viewModel.paymentOptionsModalPublisher.send(true)
                
            }) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.yellow)
                        .padding(.leading, 12)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                    
                    Text("Pay Now")
                        .font(.system(size: 16))
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(.trailing, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                }
                .overlay (
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .stroke(Color.gray, lineWidth: 0.5)
                )
            }
        }
    }
    
    var paymentOptionsModal: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    self.modalHeader
                    Divider().padding(.bottom, 10)
                    HStack(spacing: 10) {
                        Text("Required Amount:")
                            .foregroundColor(Colors.color2)
                        Text("\(self.viewModel.packChangeHelper?.payAmount.rounded(toPlaces: 2) ?? "0.0") BDT")
                            .fontWeight(.bold)
                            .foregroundColor(Colors.color2)
                    }
                    .padding(.bottom, 16)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                    HStack(spacing: 10) {
                        Text("Payable Amount")
                            .foregroundColor(Colors.color2)
                            
                        TextField("amount", text: self.$payableAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                        
                        Spacer()
                    }.padding(.leading, 16)
                    .padding(.trailing, 20)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Payment Method:")
                            .font(.headline)
                            .padding(.top, 20)
                            .foregroundColor(Colors.color2)
                        Picker("", selection: self.$selectedPayMethod) {
                            ForEach(self.viewModel.payMethods, id: \.methodId) { method in
                                Text(method.methodName ?? "Unknown method").foregroundColor(Colors.color2)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: geometry.size.width - 70, height: 150)
                    }.padding(.leading, 16)
                    .padding(.trailing, 16)
                    
                    self.payNow
                    .padding(.top, 10)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .background(ChatBubble(fillColor: Color.white, topLeft: 10, topRight: 10, bottomLeft: 10, bottomRight: 10))
                Spacer()
            }
            .padding(.top, 40)
            .padding(.bottom, 16)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .onAppear {
                withAnimation {
                    self.showChoiseBackGround = true
                }
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .top))).animation(.default)
        .zIndex(2)
    }
    
    var saveButton: some View {
        Button(action: {
            guard let packServiceId = self.selectedPackService.packServiceId, self.changingUserPackService.packServiceId != packServiceId else {
                self.viewModel.warningToastPublisher.send((true, "Select a new package first!!"))
                return
            }
            
            self.viewModel.changingUserPackService = self.changingUserPackService
            self.viewModel.selectedPackService = self.selectedPackService
            
            self.calculateAmount()
            
            guard let helper = self.viewModel.packChangeHelper else {
                self.viewModel.errorToastPublisher.send((true, "Not possible at this moment, please try again later!"))
                return
            }
            
            if self.viewModel.consumeData?.isDue == true {
                self.showingPopup.toggle()
            } else if self.viewModel.consumeData?.isDue == false {
                if helper.isUpgrade {
                    self.showPaymentOptionsModal = true
                } else {
                    self.showingPopup.toggle()
                    print("Saved amount: \(helper.savedAmount)")
                }
            }
            
        }) {
            Text("Save").bold()
        }
    }
    
    var cancelButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Text("Cancel").bold()
        }
    }
    
    init(viewModel: ProfileViewModel, changingUserPackService: UserPackService) {
        self.viewModel = viewModel
        self._changingUserPackService = State(initialValue: changingUserPackService)
        let childPackService = ChildPackService(packServiceId: changingUserPackService.packServiceId, packServiceName: changingUserPackService.packServiceName, packServicePrice: changingUserPackService.packServicePrice, packServiceTypeId: changingUserPackService.packServiceTypeId, packServiceType: changingUserPackService.packServiceType, parentPackServiceId: changingUserPackService.parentPackServiceId, parentPackServiceName: changingUserPackService.parentPackServiceName, isChecked: false, isParent: changingUserPackService.isParent)
        self._selectedPackService = State(initialValue: childPackService)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List(self.viewModel.choosingPackServiceOptions, id: \.packServiceId) { dataItem in
                        Text("\(dataItem.packServiceName ?? "Unknown") -- Price: \(dataItem.packServicePrice ?? 0.0) BDT")
                            .onTapGesture {
                                print("\(dataItem.packServiceName ?? "Unknown") -- Price: \(dataItem.packServicePrice ?? 0.0) BDT -- ID: \(dataItem.packServiceId ?? 0)")
                                self.selectedPackService = dataItem
                                self.viewModel.refactorPackageChangeSheetData(selectedPackService: dataItem)
                        }
                    }
                    Divider()
                    Text("Selected Service").font(.title).padding(.bottom, 10)
                    HStack {
                        Text("\(selectedPackService.packServiceName ?? "Unknown") -- Price: \(selectedPackService.packServicePrice ?? 0.0) BDT")
                            .font(.headline)
                            .foregroundColor(Colors.greenTheme)
                            .padding(.bottom, 60)
                            .padding(.trailing, 20)
                            .padding(.leading, 24)
                        
                        Spacer()
                    }
                    Spacer()
                }
                .actionSheet(isPresented: $showingPopup) {
                    ActionSheet(
                        title: Text("Package Change Confirmation"),
                        message: Text("Are you sure to migrate in package: \(selectedPackService.packServiceName ?? "Unknown")? which will \(viewModel.packChangeHelper?.isUpgrade == true ? "cost" : "save"): \(viewModel.packChangeHelper?.isUpgrade == true ? viewModel.packChangeHelper?.requiredAmount.rounded(toPlaces: 2) ?? "0.0" : viewModel.packChangeHelper?.savedAmount.rounded(toPlaces: 2) ?? "0.0") BDT"),
                        buttons: [.default(Text("Yes Change")) {
                            
                            self.viewModel.saveChangedPackService(selectedPackService: self.selectedPackService, changingUserPackService: self.changingUserPackService)
                            
                            }, .cancel()])
                    
                }
                .onReceive(self.viewModel.dismissPackageChangeModal.receive(on: RunLoop.main)) { shouldDismiss in
                    if shouldDismiss {
                        self.presentationMode.wrappedValue.dismiss()
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
                
                if self.showChoiseBackGround {
                    self.background
                }
                
                if self.showPaymentOptionsModal {
                    self.paymentOptionsModal
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
            .onAppear {
                self.viewModel.preparePackageChangeSheetData(changingUserPackService: self.changingUserPackService)
            }
            .navigationBarTitle(Text("Change Service"))
            .navigationBarItems(leading: cancelButton, trailing: saveButton)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    func calculateAmount() {
        let newPackServicePrice = self.selectedPackService.packServicePrice ?? 0.0
        let newPackUnitPrice = newPackServicePrice/30
        let restDays = viewModel.consumeData?.restDays ?? 0
        let newPackPrice = newPackUnitPrice * Double(restDays)
        let restAmount = viewModel.consumeData?.restAmount ?? 0.0
        let requiredAmount = newPackPrice - restAmount
        let requiredRounded = Double(requiredAmount.rounded(toPlaces: 2)) ?? 0
        if requiredAmount > 0 {
            let balanceAmount = self.viewModel.userBalance?.balanceAmount ?? 0.0
            var deductedAmount = 0.0
            if balanceAmount > 0 && balanceAmount < requiredAmount {
                deductedAmount = balanceAmount
            } else if balanceAmount > requiredAmount {
                deductedAmount = requiredAmount
            }
            
            let deductRounded = Double(deductedAmount.rounded(toPlaces: 2)) ?? 0
            
            if self.viewModel.consumeData?.isDue == true {
                let actualPayAmount = requiredAmount - deductRounded
                let actualRounded = Double(actualPayAmount.rounded(toPlaces: 2)) ?? 0
                self.viewModel.packChangeHelper = PackageChangeHelper(isUpgrade: true, requiredAmount: requiredRounded, actualPayAmount: actualRounded, payAmount: 0.0, savedAmount: 0.0, deductedAmount: deductRounded)
            } else {
                let payAmount = requiredAmount - deductRounded
                let payRounded = Double(payAmount.rounded(toPlaces: 2)) ?? 0
                self.viewModel.packChangeHelper = PackageChangeHelper(isUpgrade: true, requiredAmount: requiredRounded, actualPayAmount: payRounded, payAmount: payRounded, savedAmount: 0.0, deductedAmount: deductRounded)
            }
            
        } else if requiredAmount < 0 {
            let savedAmount = Double(abs(requiredAmount).rounded(toPlaces: 2)) ?? 0
            self.viewModel.packChangeHelper = PackageChangeHelper(isUpgrade: false, requiredAmount: 0.0, actualPayAmount: 0.0, payAmount: 0.0, savedAmount: savedAmount, deductedAmount: 0.0)
        } else if requiredAmount == 0.0 {
            self.viewModel.packChangeHelper = PackageChangeHelper(isUpgrade: false, requiredAmount: 0.0, actualPayAmount: 0.0, payAmount: 0.0, savedAmount: 0.0, deductedAmount: 0.0)
        }
    }
}
