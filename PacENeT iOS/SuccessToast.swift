//
//  SuccessToast.swift
//  Pace Cloud
//
//  Created by rgl on 13/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct SuccessToast: View {
    
    var message = ""
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            Spacer()
            VStack {
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
}

struct SuccessToast_Previews: PreviewProvider {
    static var previews: some View {
        SuccessToast()
    }
}
