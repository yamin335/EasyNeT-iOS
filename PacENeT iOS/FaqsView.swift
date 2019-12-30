//
//  FaqsView.swift
//  Pace Cloud
//
//  Created by rgl on 2/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct FaqsView: View {
    @State var showActionPopup = false
    @Environment(\.presentationMode) var presentation
    
    @State var spinCircle = false
    
    var body: some View {
        VStack {
            Text("This fucntionality is under construction")
            Button("Go Back") {
                self.presentation.wrappedValue.dismiss()
            }
        }.navigationBarTitle(Text("FAQs"))
    }
}

struct FaqsView_Previews: PreviewProvider {
    static var previews: some View {
        FaqsView()
    }
}
