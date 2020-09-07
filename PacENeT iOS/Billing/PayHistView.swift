//
//  PayHistView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/14/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct PayHistView: View {
    @ObservedObject var viewModel: BillingViewModel
    @State var userType = UserLocalStorage.getLoggedUserData()?.userTypeId
    @State var showServiceListModal = false
    let listOffset: Int = 10
    
    
    // MARK: - headerView
    var headerViewPostPaid: some View {
        HStack {
            Spacer()
            Text("Dues: \(self.viewModel.userBalance?.duesAmount?.rounded(toPlaces: 2) ?? "0.0") BDT").font(.system(size: 20, weight: .semibold, design: .rounded)).padding(.trailing, 20)
        }
    }
    
    // MARK: - headerView
    var headerViewPrePaid: some View {
        HStack {
            Spacer()
            NavigationLink(destination: PayServiceBill(viewModel: self.viewModel)) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.yellow)
                        .padding(.leading, 12)
                        .padding(.top, 14)
                        .padding(.bottom, 12)
                    
                    Text("Pay Bill Now")
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
        .padding(.trailing, 20)
        .padding(.bottom, 2)
    }
    
    var body: some View {
        VStack(spacing: 0) {
//            if userType == 1 {
//                headerViewPrePaid
//            }
            if userType == 2 {
                headerViewPostPaid
            }
            List(self.viewModel.payHistList, id: \.ispPaymentID) { item in
                PayHistRow(payHist: item).onAppear {
                    self.paymentItemAppears(item: item)
                }
            }
            .onAppear {
                self.viewModel.payHistPageNumber = -1
                self.viewModel.payHistList.removeAll()
                self.viewModel.getUserPayHistory(value: "", SDate: "", EDate: "")
                self.viewModel.getUserBalance()
            }
        }
    }
}

struct PayHistRow: View {
    @State var payHist: PayHist
    @State var title: String = "Unknown"
    
    init(payHist: PayHist) {
        self._payHist = State(initialValue: payHist)
        if let status = payHist.paymentStatus {
            let temp = status.contains("::") ? status.components(separatedBy: "::")[0] : status
            let temp1 = temp.isEmpty ? "Unknown payment" : temp
            self._title = State(initialValue: temp1)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.black)
                
                Text("Time: \(payHist.transactionDate ?? "N/A")")
                    .font(.subheadline)
                    .padding(.top, 4)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("\(payHist.paidAmount?.rounded(toPlaces: 2) ?? "0.0") BDT")
                .font(.subheadline)
                .padding(.leading, 8)
                .padding(.top, 6)
                .padding(.bottom, 6)
        }
    }
}

struct PayServiceBill: View, PayServiceBillModalShowDelegate {
    func dismissModal() {
        self.presentationMode.wrappedValue.dismiss()
    }
    
    @ObservedObject var viewModel: BillingViewModel
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        List(self.viewModel.userPackServices, id: \.userPackServiceId) { item in
            PayServiceBillRowView(item: item, viewModel: self.viewModel, payServiceBillModalShowDelegate: self)
        }.onAppear {
            self.viewModel.getUserPackServiceData()
        }.navigationBarTitle("All Services")
    }
}

protocol PayServiceBillModalShowDelegate {
    func dismissModal()
}

struct PayServiceBillRowView: View {
    @State var item: UserPackService
    @ObservedObject var viewModel: BillingViewModel
    let payServiceBillModalShowDelegate: PayServiceBillModalShowDelegate
    @State private var showBalanceRechargeAlert = false
    
    var payButton: some View {
        Text("Pay")
            .font(.system(size: 14))
            .font(.body)
            .onTapGesture {
                var amount = 0.0
                if self.item.activeDate != nil {
                    amount = self.item.packServicePrice ?? 0.0
                } else {
                    let temp1 = self.item.packServiceOthersCharge ?? 0.0
                    let temp2 = self.item.packServiceInstallCharge ?? 0.0
                    amount = self.item.packServicePrice ?? 0.0 + temp1 + temp2
                }
                
                if amount > 0.0 {
                    let userBalance = self.viewModel.userBalance?.balanceAmount ?? 0.0
                    
                    if userBalance >= amount {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: amount, deductedAmount: amount, invoiceId: 0, userPackServiceId: self.item.userPackServiceId, canModify: false, isChildInvoice: false)
                        self.showBalanceRechargeAlert = true
                    } else {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: amount - userBalance, deductedAmount: userBalance, invoiceId: 0, userPackServiceId: self.item.userPackServiceId, canModify: false, isChildInvoice: false)
                        self.payServiceBillModalShowDelegate.dismissModal()
                        self.viewModel.paymentOptionsModalPublisher.send(true)
                    }
                } else {
                    self.viewModel.errorToastPublisher.send((true, "Amount must be greater than 0.0 BDT"))
                }
            }
            .foregroundColor(Colors.color7)
            .padding(.trailing, 10)
            .padding(.leading, 10)
            .padding(.top, 4)
            .padding(.bottom, 4)
            .overlay (
                RoundedRectangle(cornerRadius: 4, style: .circular)
                    .stroke(Color.gray, lineWidth: 0.5)
            ).alert(isPresented:$showBalanceRechargeAlert) {
                Alert(title: Text("Confirm Recharge"), message: Text("Are you sure to pay from your balance?"), primaryButton: .destructive(Text("Yes")) {
                    self.payServiceBillModalShowDelegate.dismissModal()
                    self.viewModel.payFromBalance()
                    }, secondaryButton: .cancel(Text("No")))
            }
    }
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.packServiceName?.isEmpty ?? false ? "Unknown" : item.packServiceName ?? "Unknown")
                        .bold()
                        .font(.system(size: 15))
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Circle()
                        .frame(width: 18, height: 18)
                        .foregroundColor(item.isActive == false ? Color.red : Colors.greenTheme)
                        .padding(.all, 1)
                }
                
                Text("Price: \(item.packServicePrice?.rounded(toPlaces: 2) ?? "0.0") BDT")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .font(.body)
                
                Text("Charges: \(calculateCharges(item: item).rounded(toPlaces: 2)) BDT")
                .foregroundColor(.gray)
                .font(.system(size: 14))
                .font(.body)
            }
            Spacer()
            //payButton
        }.padding(.top, 4).padding(.bottom, 4)
    }
    
    func calculateCharges(item: UserPackService) -> Double {
        let temp1 = item.packServiceOthersCharge ?? 0.0
        let temp2 = item.packServiceInstallCharge ?? 0.0
        return  temp1 + temp2
    }
}

extension RandomAccessCollection where Self.Element == PayHist {
    
    func isLastItem(item: PayHist) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard let itemIndex = firstIndex(where: { $0.ispPaymentID == item.ispPaymentID }) else {
            return false
        }
        
        let distance = self.distance(from: itemIndex, to: endIndex)
        return distance == 1
    }
    
    func isThresholdItem(offset: Int, item: PayHist) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard let itemIndex = firstIndex(where: { $0.ispPaymentID == item.ispPaymentID }) else {
            return false
        }
        
        let distance = self.distance(from: itemIndex, to: endIndex)
        let offset = offset < count ? offset : count - 1
        return offset == (distance - 1)
    }
}

extension PayHistView {
    private func paymentItemAppears(item: PayHist) {
        if self.viewModel.payHistList.isThresholdItem(offset: listOffset, item: item) {
            print("Paging Working...")
            if self.viewModel.payHistList.count > 30 {
                //isLoading = true
                viewModel.getUserPayHistory(value: "", SDate: "", EDate: "")
                print("Working...")
            }
        }
    }
}
