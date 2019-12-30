//
//  SpinLoaderView.swift
//  Pace Cloud
//
//  Created by rgl on 9/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import Foundation
import SwiftUI

struct SpinLoaderView: View {
    
    @State var spinCircle = false
    
    var body: some View {
        ZStack {
            Rectangle().frame(width:160, height: 135).background(Color.black).cornerRadius(8).blur(radius: 0.5, opaque: false).opacity(0.7).shadow(color: .black, radius: 15)
            VStack {
                Circle()
                    .trim(from: 0.3, to: 1)
                    .stroke(Colors.greenTheme, lineWidth:3)
                    .frame(width:40, height: 40)
                    .padding(.all, 8)
                    .rotationEffect(.degrees(spinCircle ? 0 : -360), anchor: .center)
                    .animation(Animation.linear(duration: 0.6).repeatForever(autoreverses: false))
                    .onAppear {
                        self.spinCircle = true
                    }
                Text("Please wait...").foregroundColor(.white)
            }
        }
    }
}

struct SpinLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        SpinLoaderView()
    }
}
