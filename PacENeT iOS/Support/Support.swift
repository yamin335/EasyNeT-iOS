//
//  Support.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct Support: View {
    
    @EnvironmentObject var userData: UserData
    @ObservedObject var viewModel = SupportViewModel()
    @State private var showSignoutAlert = false
    @State private var isLoading: Bool = false
    @State private var showLoader = false
    private let offset: Int = 10
    
    var signoutButton: some View {
        Button(action: {
            self.showSignoutAlert = true
        }) {
            Text("Sign Out")
                .foregroundColor(Colors.greenTheme)
        }
        .alert(isPresented:$showSignoutAlert) {
            Alert(title: Text("Sign Out"), message: Text("Are you sure to sign out?"), primaryButton: .destructive(Text("Yes")) {
                self.userData.isLoggedIn = false
                self.userData.selectedTabItem = 0
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var refreshButton: some View {
        Button(action: {
            self.viewModel.refreshUI()
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .light))
                .imageScale(.large)
                .accessibility(label: Text("Refresh"))
                .padding()
                .foregroundColor(Colors.greenTheme)
            
        }
    }
    
    var newTicket: some View {
        NavigationLink(destination: SupportTicketEntry(viewModel: viewModel)) {
            Text("New Ticket")
            .foregroundColor(Colors.greenTheme)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                List(self.viewModel.supportTicketList, id: \.ispTicketId) { item in
                    NavigationLink(destination: SupportTicketDetail(viewModel: self.viewModel, item: item)) {
                        SupportTicketRow(item: item).onAppear {
                            self.listItemAppears(item: item)
                        }
                    }
                }.onDisappear {
                    UITableView.appearance().separatorStyle = .singleLine
                }
            }
            .onReceive(self.viewModel.showLoader.receive(on: RunLoop.main)) { shouldShow in
                self.showLoader = shouldShow
            }
            .onAppear {
                self.viewModel.pageNumber = -1
                self.viewModel.supportTicketList.removeAll()
                self.viewModel.getSupportTicketList()
            }
            .navigationBarTitle(Text("Support"))
                .navigationBarItems(leading: refreshButton, trailing: newTicket)
            
            if self.showLoader {
                SpinLoaderView()
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Support_Previews: PreviewProvider {
    static var previews: some View {
        Support().environmentObject(UserData())
    }
}

extension RandomAccessCollection where Self.Element == SupportTicket {
    
    func isLastTicketItem(item: SupportTicket) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard let itemIndex = firstIndex(where: { $0.ispTicketId == item.ispTicketId }) else {
            return false
        }
        
        let distance = self.distance(from: itemIndex, to: endIndex)
        return distance == 1
    }
    
    func isThresholdItem(offset: Int, item: SupportTicket) -> Bool {
        guard !isEmpty else {
            return false
        }
        
        guard let itemIndex = firstIndex(where: { $0.ispTicketId == item.ispTicketId }) else {
            return false
        }
        
        let distance = self.distance(from: itemIndex, to: endIndex)
        let offset = offset < count ? offset : count - 1
        return offset == (distance - 1)
    }
}

extension Support {
    private func listItemAppears(item: SupportTicket) {
        if self.viewModel.supportTicketList.isThresholdItem(offset: offset,
                                          item: item) {
            print("Paging Working...")
            if self.viewModel.supportTicketList.count > 30 {
                isLoading = true
                viewModel.getSupportTicketList()
                print("Working...")
            }
        }
    }
}
