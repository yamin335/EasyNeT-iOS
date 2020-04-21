//
//  PrivacyView.swift
//  Pace Cloud
//
//  Created by rgl on 2/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct PrivacyView: View {
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            Text("This fucntionality is under development")
            Button("Go Back") {
                self.presentation.wrappedValue.dismiss()
            }
        }.navigationBarTitle(Text("Privacy"))
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyView()
    }
}
