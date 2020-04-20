//
//  Utils.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/18/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI
import Foundation
import Combine

// MARK: - ViewModifierOnKeyboardAppear
struct ViewModifierOnKeyboardAppear: ViewModifier {
    @State var bottomPadding: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.bottomPadding)
                .animation(.easeOut(duration: 0.15))
                .onAppear(perform: {
                    NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillShowNotification)
                        .merge(with: NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillChangeFrameNotification))
                        .compactMap { notification in
                            notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? CGRect
                    }
                    .map { rect in
                        rect.height - geometry.safeAreaInsets.bottom
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.bottomPadding))

                    NotificationCenter.Publisher(center: NotificationCenter.default, name: UIResponder.keyboardWillHideNotification)
                        .compactMap { notification in
                            CGFloat.zero
                    }
                    .subscribe(Subscribers.Assign(object: self, keyPath: \.bottomPadding))
                })
        }
    }
}

// MARK: - SuccessToast
struct SuccessToast: View {
    var message = ""
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center) {
                Spacer()
                Text(self.message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.bottom, 10)
            .padding(.top, 10)
            .background(Colors.greenTheme)
            .cornerRadius(8)
            .shadow(color: .black, radius: 10)
            .transition(.slide)
            
        }.padding(.leading, 32).padding(.trailing, 32).padding(.bottom, 20).padding(.top, 20)
    }
}

// MARK: - ErrorToast
struct ErrorToast: View {
    var message = ""
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center) {
                Spacer()
                Text(self.message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.bottom, 10)
            .padding(.top, 10)
            .background(Color.red)
            .cornerRadius(8)
            .shadow(color: .black, radius: 10)
            .transition(.slide)
        }
        .padding(.leading, 32)
        .padding(.trailing, 32)
        .padding(.bottom, 20)
        .padding(.top, 20)
    }
}

// MARK: - WarningToast
struct WarningToast: View {
    var message = ""
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .center) {
                Spacer()
                Text(self.message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.bottom, 10)
            .padding(.top, 10)
            .background(Color.yellow)
            .cornerRadius(8)
            .shadow(color: .black, radius: 10)
            .transition(.slide)
        }
        .padding(.leading, 32)
        .padding(.trailing, 32)
        .padding(.bottom, 20)
        .padding(.top, 20)
    }
}
