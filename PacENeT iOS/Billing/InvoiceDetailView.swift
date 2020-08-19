//
//  InvoiceDetailView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/13/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

protocol ChildInvoicePayCallback {
    func onPayClicked()
}

struct ParticularRow: View {
    @State var item: ChildInvoice
    @ObservedObject var viewModel: BillingViewModel
    let delegate: ChildInvoicePayCallback
    @State private var showBalanceRechargeAlert = false
    
    // MARK: - payButton
    var payButton: some View {
        Text("Pay Now")
            .font(.system(size: 14))
            .font(.body)
            .onTapGesture {
                print("Working...")
                let userBalance = self.viewModel.userBalance?.balanceAmount ?? 0.0
                
                guard let invoiceAmount = self.item.dueAmount,
                    let invoiceId = self.item.ispInvoiceId else {
                    return
                }
                
                if invoiceAmount > 0.0 {
                    if userBalance >= invoiceAmount {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: invoiceAmount, deductedAmount: invoiceAmount, invoiceId: invoiceId, userPackServiceId: 0, canModify: false, isChildInvoice: true)
                        self.showBalanceRechargeAlert = true
                    } else {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: invoiceAmount - userBalance, deductedAmount: userBalance, invoiceId: invoiceId, userPackServiceId: 0, canModify: false, isChildInvoice: true)
                        self.delegate.onPayClicked()
                        self.viewModel.paymentOptionsModalPublisher.send(true)
                    }
                } else {
                    self.viewModel.errorToastPublisher.send((true, "Amount must be greater than 0.0 BDT"))
                }
            }.foregroundColor(Colors.color7)
            .padding(.trailing, 10)
            .padding(.leading, 10)
            .padding(.top, 4)
            .padding(.bottom, 4)
            .overlay (
                RoundedRectangle(cornerRadius: 4, style: .circular)
                    .stroke(Color.gray, lineWidth: 0.5)
            )
            .alert(isPresented:$showBalanceRechargeAlert) {
            Alert(title: Text("Confirm Recharge"), message: Text("Are you sure to pay from your balance?"), primaryButton: .destructive(Text("Yes")) {
                self.delegate.onPayClicked()
                self.viewModel.payFromBalance()
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.packageName ?? "Unknown").font(.callout).fontWeight(.semibold)
                Text(item.invoiceNo ?? "Unknown").font(.footnote).foregroundColor(.gray)
                Text("Due: \(item.dueAmount?.rounded(toPlaces: 2) ?? "0.0") BDT")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text("Tax: \(item.taxAmount?.rounded(toPlaces: 2) ?? "0.0") | Discount: \(item.discountAmount?.rounded(toPlaces: 2) ?? "0.0")")
                .font(.footnote)
                .foregroundColor(.gray)
            }
            Spacer()
            VStack {
                Text("\(item.invoiceTotal?.rounded(toPlaces: 2) ?? "0.0") BDT").font(.callout)
                payButton
            }
            
        }.padding(.bottom, 10)
    }
}

struct InvoiceDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BillingViewModel
    @State var invoice: Invoice
    @State private var showBalanceRechargeAlert = false
    
    // MARK: - payButton
    var payButton: some View {
        HStack {
            Spacer()
            Button(action: {
                let userBalance = self.viewModel.userBalance?.balanceAmount ?? 0.0
                
                guard let invoiceAmount = self.invoice.dueAmount,
                    let invoiceId = self.invoice.ispInvoiceParentId else {
                    return
                }
                
                if invoiceAmount > 0.0 {
                    if userBalance >= invoiceAmount {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: invoiceAmount, deductedAmount: invoiceAmount, invoiceId: invoiceId, userPackServiceId: 0, canModify: false, isChildInvoice: false)
                        self.showBalanceRechargeAlert = true
                    } else {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: invoiceAmount - userBalance, deductedAmount: userBalance, invoiceId: invoiceId, userPackServiceId: 0, canModify: false, isChildInvoice: false)
                        self.presentationMode.wrappedValue.dismiss()
                        self.viewModel.paymentOptionsModalPublisher.send(true)
                    }
                } else {
                    self.viewModel.errorToastPublisher.send((true, "Amount must be greater than 0.0 BDT"))
                }
            
            }) {
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
                
            }.alert(isPresented:$showBalanceRechargeAlert) {
                Alert(title: Text("Confirm Recharge"), message: Text("Are you sure to pay from your balance?"), primaryButton: .destructive(Text("Yes")) {
                    self.presentationMode.wrappedValue.dismiss()
                    self.viewModel.payFromBalance()
                    }, secondaryButton: .cancel(Text("No")))
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 5)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image("pace_net")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .scaledToFit().overlay(RoundedRectangle(cornerRadius: 4, style: .circular)
                            .stroke(Color.gray, lineWidth: 0.2))
                    Spacer()
                    Text("Date: \(invoice.createDate?.formatDate() ?? "N/A")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Text("Invoice No: \(invoice.invoiceNo ?? "N/A")")
                    .font(.system(size: 20, weight: .regular, design: .default))
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Billed To")
                        .font(.system(size: 20, weight: .bold, design: .default)).underline(true, color: .black)
                    Text(invoice.fullName ?? "N/A").fontWeight(.semibold)
                    Text("Client ID: \(invoice.userCode ?? "N/A")")
                    Text("Billing Period: \(invoice.fromDate?.formatDate() ?? "N/A")  to  \(invoice.toDate?.formatDate() ?? "N/A")")
                    Text("Address: \(invoice.address ?? "N/A")")
                }
                HStack {
                    Spacer()
                    Text("Particulars")
                        .font(.system(size: 20, weight: .bold, design: .default))
                    Spacer()
                }.padding(.top, 8)
                
                Divider()
                
                VStack {
                    ForEach(self.viewModel.invoiceDetailList, id: \.id) { item in
                        ParticularRow(item: item, viewModel: self.viewModel, delegate: self)
                    }
                }.padding(.bottom, 24)
                
                HStack {
                    Spacer()
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tax:")
                            Spacer()
                            Text("\(invoice.taxAmount?.rounded(toPlaces: 2) ?? "0.0") BDT")
                        }
                        HStack {
                            Text("Discount:")
                            Spacer()
                            Text("\(invoice.discountAmount?.rounded(toPlaces: 2) ?? "0.0") BDT")
                        }
                        
                        Rectangle().frame(width: 250, height: 1).foregroundColor(.gray)
                        
                        HStack {
                            Text("Total:")
                            Spacer()
                            Text("\(invoice.invoiceTotal?.rounded(toPlaces: 2) ?? "0.0") BDT")
                        }
                    }.frame(width: 250)
                }
                
                if showPayButton(isPaid: invoice.isPaid) {
                    payButton
                }
                
            }.padding()
        }
        .onAppear {
            self.viewModel.invoiceDetailList.removeAll()
            self.viewModel.getUserInvoiceDetails(SDate: self.invoice.fromDate ?? "", EDate: self.invoice.toDate ?? "", CDate: self.invoice.createDate ?? "", invId: self.invoice.ispInvoiceParentId ?? 0)
        }.navigationBarTitle(invoice.genMonth ?? "Invoice Details")
    }
    
    func showPayButton(isPaid: Bool?) -> Bool {
        guard let paidOrNot = isPaid else {
            return false
        }
        
        return !paidOrNot
    }
}

extension InvoiceDetailView: ChildInvoicePayCallback {
    func onPayClicked() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

//struct InvoiceDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        InvoiceDetailView()
//    }
//}
