//
//  BKashWebViewModal.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/19/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// MARK: - BkashWebViewModal
struct BkashWebViewModal: View {
    @ObservedObject var viewModel: BillingViewModel
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Spacer()
                Button(action: {
                    self.viewModel.bkashWebViewNavigationPublisher.send("Back")
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.gray)
                }
                Spacer()
                Divider()
                Spacer()
                Button(action: {
                    self.viewModel.bkashWebViewNavigationPublisher.send("Next")
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.gray)
                }
                Spacer()
            }.frame(height: 30)
            Divider()
            BKashWebView(viewModel: self.viewModel)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.white)
    }
}
