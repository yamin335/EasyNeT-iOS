//
//  PackageChangeView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/4/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct PackageChangeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProfileViewModel
    @State var changingUserPackService: UserPackService
    @State var showingPopup = false
    @State var selectedPackService: ChildPackService
    
    var saveButton: some View {
        Button(action: {
            //self.showingPopup.toggle()
        }) {
            Text("Save Changes").bold()
        }.actionSheet(isPresented: $showingPopup) {
            ActionSheet(
                title: Text("Service Change Confirmation"),
                message: Text("Are you sure to change this service?"),
                buttons: [.default(Text("Yes Change")) {
                    self.presentationMode.wrappedValue.dismiss()
                    }, .cancel()])
            
        }
    }
    
    var cancelButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Text("Cancel").bold()
        }
    }
    
    init(viewModel: ProfileViewModel, changingUserPackService: UserPackService) {
        self.viewModel = viewModel
        self._changingUserPackService = State(initialValue: changingUserPackService)
        let childPackService = ChildPackService(packServiceId: changingUserPackService.packServiceId, packServiceName: changingUserPackService.packServiceName, packServicePrice: changingUserPackService.packServicePrice, packServiceTypeId: changingUserPackService.packServiceTypeId, packServiceType: changingUserPackService.packServiceType, parentPackServiceId: changingUserPackService.parentPackServiceId, parentPackServiceName: changingUserPackService.parentPackServiceName, isChecked: false, isParent: changingUserPackService.isParent)
        self._selectedPackService = State(initialValue: childPackService)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List(self.viewModel.choosingPackServiceOptions, id: \.packServiceId) { dataItem in
                    Text("\(dataItem.packServiceName ?? "Unknown") -- Price: \(dataItem.packServicePrice ?? 0.0) BDT")
                        .onTapGesture {
                        print("\(dataItem.packServiceName ?? "Unknown") -- Price: \(dataItem.packServicePrice ?? 0.0) BDT")
                            self.selectedPackService = dataItem
                            self.viewModel.refactorPackageChangeSheetData(selectedPackService: dataItem)
                    }
                }
                Divider()
                Text("Selected Service").font(.title).padding(.bottom, 10)
                HStack {
                    Text("\(selectedPackService.packServiceName ?? "Unknown") -- Price: \(selectedPackService.packServicePrice ?? 0.0) BDT")
                        .font(.headline)
                        .foregroundColor(Colors.greenTheme)
                        .padding(.bottom, 60)
                        .padding(.trailing, 20)
                        .padding(.leading, 24)
                    
                    Spacer()
                }
                Spacer()
            }
            .onAppear {
                self.viewModel.preparePackageChangeSheetData(changingUserPackService: self.changingUserPackService)
            }
            .navigationBarTitle(Text("Change Service"))
            .navigationBarItems(leading: cancelButton, trailing: saveButton)
        }
    }
}
