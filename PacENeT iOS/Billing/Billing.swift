//
//  Billing.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI
import Foundation
import Combine
import UIKit
import WebKit

struct Billing: View {
    
    // MARK: - Property declarations
    @EnvironmentObject var userData: UserData
    @ObservedObject var viewModel = BillingViewModel()
    
    @State var showFosterWebView = false
    @State var showBkashWebView = false
    
    // Toasts
    @State var showSuccessToast = false
    @State var successMessage: String = ""
    @State var showWarningToast = false
    @State var warningMessage: String = ""
    @State var showErrorToast = false
    @State var errorMessage: String = ""
    
    @State private var showLoader = false
    
    @State private var options = ["Invoice", "Payment"]
    @State private var selectedOption = 0
    
    @State var showPaymentOptionsModal = false
    @State var showChoiseBackGround = false
    
    
    // MARK: - refreshButton
    var refreshButton: some View {
        Button(action: {
            if self.selectedOption == 0 {
                self.viewModel.refreshInvoice()
            } else if self.selectedOption == 1 {
                self.viewModel.refreshPayment()
            }
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .light))
                .imageScale(.large)
                .accessibility(label: Text("Refresh"))
                .padding()
                .foregroundColor(Colors.greenTheme)
            
        }
    }
    
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
            Text("Debit/Credit Cards")
                .font(.headline)
                .foregroundColor(Colors.color2).padding(.top, 8)
            
            HStack {
                Spacer()
                Image("visa_card_logo")
                .resizable()
                .frame(width: 250, height: 90)
                .scaledToFit()
                .overlay (
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .stroke(Color.gray, lineWidth: 0.5)
                ).onTapGesture {
                    withAnimation {
                        self.showPaymentOptionsModal = false
                        self.showChoiseBackGround = false
                    }
                    self.viewModel.getFosterPaymentUrl()
                }
                Spacer()
            }.padding(.top, 6)
            
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
                    withAnimation {
                        self.showPaymentOptionsModal = false
                        self.showChoiseBackGround = false
                    }
                    if self.viewModel.bkashTokenModel != nil {
                        self.viewModel.showBkashWebViewPublisher.send(true)
                    } else {
                        self.viewModel.getBkashToken()
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
            
            Text("\(viewModel.billPaymentHelper?.balanceAmount.rounded(toPlaces: 2) ?? "0.0") BDT")
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

    // MARK: - Main Body
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    VStack {
                        if self.selectedOption == 0 {
                            InvoiceView(viewModel: self.viewModel)
                        } else if self.selectedOption == 1 {
                            PayHistView(viewModel: self.viewModel)
                                
                        }
                    }
                    
                    if self.showChoiseBackGround {
                        self.background
                    }
                    
                    if self.showPaymentOptionsModal {
                        self.paymentOptionsModal
                    }
                    
                    VStack {
                        if self.showFosterWebView {
                            FosterWebViewModal(viewModel: self.viewModel)
                        } else if self.showBkashWebView {
                            BkashWebViewModal(viewModel: self.viewModel)
                        }
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
                        }
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
                        }
                    }

                    if self.showLoader {
                        SpinLoaderView()
                    }
                }
                .onReceive(self.viewModel.paymentOptionsModalPublisher.receive(on: RunLoop.main)) { shouldShow in
                    self.showPaymentOptionsModal = shouldShow
                }
                .onReceive(self.viewModel.showFosterWebViewPublisher.receive(on: RunLoop.main)) { shouldShow in
                    self.showFosterWebView = shouldShow
                }
                .onReceive(self.viewModel.showBkashWebViewPublisher.receive(on: RunLoop.main)) { shouldShow in
                    self.showBkashWebView = shouldShow
                    self.showLoader = true
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
                }.navigationBarTitle(Text(self.selectedOption == 0 ? "Invoices" : "Payments"))
                    .navigationBarItems(leading: self.refreshButton, trailing: HStack {
                        Picker("", selection: self.$selectedOption) {
                            ForEach(0 ..< self.options.count) {
                                Text(self.options[$0])
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                        .padding(.trailing, (geometry.size.width / 2.0) - 120)
                    })
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
