//
//  PackServiceRowView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/4/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct PackServiceRowView: View {
    @State var item: UserPackService
    @ObservedObject var viewModel: ProfileViewModel
    
    var changeButton: some View {
        Text("Change")
            .font(.system(size: 14))
            .font(.body)
            .onTapGesture {
                if self.item.packServiceTypeId == 1 {
                    self.viewModel.getPayMethodsAndConsumeData(selectedPackServiceId: self.item.userPackServiceId)
                } else {
                    self.viewModel.warningToastPublisher.send((true, "Please contact with our office!"))
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
            )
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
                
                Text("Active: \(item.activeDate?.formatDate() ?? "N/A") to \(item.expireDate?.formatDate() ?? "N/A")")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                    .font(.body)
            }
            Spacer()
            changeButton
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
        .onReceive(self.viewModel.showPackageChangePayModalPublisher.receive(on: RunLoop.main)) { (payMethods, consumeData) in
            
            guard consumeData.isPossibleChange == true else {
                self.viewModel.warningToastPublisher.send((true, "Try next day again! or contact with support"))
                return
            }
            
            self.viewModel.payMethods = payMethods
            self.viewModel.consumeData = consumeData
            self.viewModel.showServiceChangeModal.send((true, self.item))
            print("RestDays: \(consumeData.restDays ?? 0), RestAmount: \(consumeData.restAmount ?? 0.0)")
        }
    }
}
