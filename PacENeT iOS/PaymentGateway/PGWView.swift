//
//  BkashPGWView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 5/20/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

enum PGW {
    case BKASH
    case FOSTER
}

// MARK: - PGWView
struct PGWView: View {
    @ObservedObject var viewModel: PGWViewModel
    @State var pgw: PGW
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Spacer()
                Button(action: {
                    switch self.pgw {
                    case .BKASH:
                        self.viewModel.bkashWebViewNavigationPublisher.send("Back")
                    case .FOSTER:
                        self.viewModel.fosterWebViewNavigationPublisher.send("Back")
                    }
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
                    switch self.pgw {
                    case .BKASH:
                        self.viewModel.bkashWebViewNavigationPublisher.send("Next")
                    case .FOSTER:
                        self.viewModel.fosterWebViewNavigationPublisher.send("Next")
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.gray)
                }
                Spacer()
            }.frame(height: 30)
            Divider()
            
            if self.pgw == .BKASH {
                BkashPGW(viewModel: self.viewModel)
            } else {
                FosterPGW(viewModel: self.viewModel)
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.white)
    }
}
