//
//  SplashScreen.swift
//  Pace Cloud
//
//  Created by rgl on 30/9/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct SplashScreen: View {
    @State var imageAlpha = 0.0
    let splashTime = 1.0
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            HStack(alignment: .center) {
                Spacer()
                Image("pacenet_white")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .opacity(imageAlpha)
                    .onAppear(){
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: self.splashTime)) {
                                self.imageAlpha = 1
                            }
                        }
                    }
                Spacer()
            }
            Spacer()
        }
        .background(Image("splash_background").resizable().scaledToFill())
        .edgesIgnoringSafeArea(.all)
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
