//
//  InvoiceView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/13/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct InvoiceRow: View {
    @State var invoice: Invoice
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(invoice.invoiceNo ?? "Unknown")
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.black)
                
                Text("Month: \(invoice.genMonth ?? "N/A")")
                    .font(.subheadline)
                    .padding(.top, 4)
                    .foregroundColor(.gray)
                
                Text("Amount: \(invoice.invoiceTotal?.rounded(toPlaces: 2) ?? "0.0") BDT")
                .font(.subheadline)
                .padding(.top, 4)
                .foregroundColor(.gray)
            }
            Spacer()
            VStack {
                Text(getStatus(isPaid: invoice.isPaid))
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                    .padding(.trailing, 8)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
            }
            .background(getStatusColor(isPaid: invoice.isPaid))
            .cornerRadius(5)
        }
    }
    
    func getStatus(isPaid: Bool?) -> String {
        switch isPaid {
        case true:
            return "Paid"
        case false:
            return "Due"
        default:
            return "N/A"
        }
    }
    
    func getStatusColor(isPaid: Bool?) -> Color {
        switch isPaid {
        case false:
            return Color.red
        case true:
            return Color.green
        default:
            return Color.gray
        }
    }
}



struct InvoiceView: View {
    @ObservedObject var viewModel: BillingViewModel
    let listOffset: Int = 10
    var body: some View {
        List(self.viewModel.invoiceList, id: \.ispInvoiceId) { item in
            NavigationLink(destination: InvoiceDetailView(viewModel: self.viewModel, invoice: item)) {
                InvoiceRow(invoice: item).onAppear {
                    self.invoiceItemAppears(item: item)
                }
            }
        }
        .onAppear {
            self.viewModel.invoicePageNumber = -1
            self.viewModel.invoiceList.removeAll()
            self.viewModel.getUserInvoiceList()
        }
    }
}

extension RandomAccessCollection where Self.Element == Invoice {
    
    func isLastItem(item: Invoice) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard let itemIndex = firstIndex(where: { $0.ispInvoiceId == item.ispInvoiceId }) else {
            return false
        }
        
        let distance = self.distance(from: itemIndex, to: endIndex)
        return distance == 1
    }
    
    func isThresholdItem(offset: Int, item: Invoice) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard let itemIndex = firstIndex(where: { $0.ispInvoiceId == item.ispInvoiceId }) else {
            return false
        }
        
        let distance = self.distance(from: itemIndex, to: endIndex)
        let offset = offset < count ? offset : count - 1
        return offset == (distance - 1)
    }
}

extension InvoiceView {
    private func invoiceItemAppears(item: Invoice) {
        if self.viewModel.invoiceList.isThresholdItem(offset: listOffset, item: item) {
            print("Paging Working...")
            if self.viewModel.invoiceList.count > 30 {
                //isLoading = true
                viewModel.getUserInvoiceList()
                print("Working...")
            }
        }
    }
}
