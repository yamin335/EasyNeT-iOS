//
//  InvoiceDetailView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/13/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct ParticularRow: View {
    @State var name: String
    @State var price: Double
    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Text("\(price.rounded(toPlaces: 2)) BDT")
        }
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
                
                guard let invoiceAmount = self.invoice.dueAmount, let packServiceId = self.invoice.userPackServiceId, let invoiceId = self.invoice.ispInvoiceId else {
                    return
                }
                
                if invoiceAmount > 0.0 {
                    if userBalance >= invoiceAmount {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: invoiceAmount, deductedAmount: invoiceAmount, invoiceId: invoiceId, userPackServiceId: packServiceId)
                        self.showBalanceRechargeAlert = true
                    } else {
                        self.viewModel.billPaymentHelper = BillPaymentHelper(balanceAmount: invoiceAmount - userBalance, deductedAmount: userBalance, invoiceId: invoiceId, userPackServiceId: packServiceId)
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
                    ForEach(self.viewModel.invoiceDetailList, id: \.packageId) { item in
                        ParticularRow(name: item.packageName ?? "N/A", price: item.packagePrice ?? 0.0)
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
            self.viewModel.getUserInvoiceDetails(SDate: self.invoice.fromDate ?? "", EDate: self.invoice.toDate ?? "", CDate: self.invoice.createDate ?? "", invId: self.invoice.ispInvoiceId ?? 0, userPackServiceId: self.invoice.userPackServiceId ?? 0)
        }.navigationBarTitle(invoice.genMonth ?? "Invoice Details")
    }
    
    func showPayButton(isPaid: Bool?) -> Bool {
        guard let paidOrNot = isPaid else {
            return false
        }
        
        return !paidOrNot
    }
}

//struct InvoiceDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        InvoiceDetailView()
//    }
//}
