//
//  Dashboard.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI
import Charts
import Combine

struct Dashboard: View {
    
    @EnvironmentObject var userData: UserData
    @State private var showSignoutAlert = false
    @ObservedObject var dashboardViewModel = DashboardViewModel()
    @State private var showSessionChart = false
    
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
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var refreshButton: some View {
        Button(action: {
//            self.viewModel.refreshUI()
            
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .light))
                .imageScale(.large)
                .accessibility(label: Text("Refresh"))
                .padding()
                .foregroundColor(Colors.greenTheme)
            
        }
    }
    
    var shortCutMenu: some View {
        GeometryReader { window in
            VStack(alignment: .center, spacing: 14) {
                HStack(alignment: .top) {
                    Spacer()
                    VStack {
                        Image("my_account")
                            .resizable()
                            .frame(width: self.getImageSize(size: window.size.width), height: self.getImageSize(size: window.size.width))
                            
                        Text("My Account")
                            .frame(width: self.getImageSize(size: window.size.width))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)
                    .onTapGesture {
                        self.userData.selectedTabItem = 1
                    }
                    Spacer()
                    VStack {
                        Image("pay_now")
                            .resizable()
                            .frame(width: self.getImageSize(size: window.size.width), height: self.getImageSize(size: window.size.width))
                          
                        Text("Pay Now")
                            .frame(width: self.getImageSize(size: window.size.width))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)
                    .onTapGesture {
                        self.userData.selectedTabItem = 2
                    }
                    Spacer()
                    VStack {
                        Image("pay_history")
                            .resizable()
                            .frame(width: self.getImageSize(size: window.size.width), height: self.getImageSize(size: window.size.width))
                          
                        Text("Payment History")
                            .frame(width: self.getImageSize(size: window.size.width))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)
                    .onTapGesture {
                        self.userData.selectedTabItem = 2
                    }
                    Spacer()
                }
                
                HStack(alignment: .top) {
                    Spacer()
                    VStack {
                        Image("packages")
                            .resizable()
                            .frame(width: self.getImageSize(size: window.size.width), height: self.getImageSize(size: window.size.width))
                          
                        Text("Packages")
                            .frame(width: self.getImageSize(size: window.size.width))
                    }
                    .onTapGesture {
                        self.userData.selectedTabItem = 1
                    }
                    Spacer()
                    VStack {
                        Image("open_ticket")
                            .resizable()
                            .frame(width: self.getImageSize(size: window.size.width), height: self.getImageSize(size: window.size.width))
                            
                        Text("Open Ticket")
                            .frame(width: self.getImageSize(size: window.size.width))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .onTapGesture {
                        self.userData.selectedTabItem = 3
                    }
                    Spacer()
                    VStack {
                        Image("ticket_history")
                            .resizable()
                            .frame(width: self.getImageSize(size: window.size.width), height: self.getImageSize(size: window.size.width))
                          
                        Text("Ticket History")
                            .frame(width: self.getImageSize(size: window.size.width))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .onTapGesture {
                        self.userData.selectedTabItem = 3
                    }
                    Spacer()
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                self.shortCutMenu.frame(minWidth: 0, maxWidth: .infinity)

                GeometryReader { geometry in
                    ZStack {
                        if self.showSessionChart {
                            LineChartSwiftUI(viewModel: self.dashboardViewModel)
                        } else {
                            Text("No Session Data Found")
                                .foregroundColor(Colors.color3)
                        }
                        
                    }.frame(width: geometry.size.width, height: geometry.size.height - 30).padding(.top, 20)
                }
                .onReceive(self.dashboardViewModel.sessionChartDataPublisher.receive(on: RunLoop.main)) { value in
                    
                    if value {
                        self.showSessionChart = true
                    } else {
                        self.showSessionChart = false
                    }
                }
            }.onAppear() {
                self.dashboardViewModel.getSessionChartData()
            }.onDisappear() {
                self.showSessionChart = false
            }
            .navigationBarTitle(Text("Dashboard"), displayMode: .inline)
                .navigationBarItems(leading: refreshButton, trailing: signoutButton)
        }
    }
    
    func getImageSize(size: CGFloat) -> CGFloat {
        return (size - 4*16)/3
    }
}

struct LineChartSwiftUI: UIViewRepresentable {
    let viewModel: DashboardViewModel
    let lineChart = LineChartView()

    func makeUIView(context: Context) -> LineChartView {
        return lineChart
    }

    func updateUIView(_ lineChartView: LineChartView, context: Context) {
        setUpChart(chartView: lineChartView , sessionChartDataList: viewModel.sessionChartData)
    }

    func setUpChart(chartView: LineChartView, sessionChartDataList: [SessionChartData]?) {
        guard let sessionChartData = sessionChartDataList else {
            return
        }
        var labels = [String]()
        for data in sessionChartData {
            labels.append(data.dataName)
        }
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:labels)
        chartView.xAxis.granularity = 1
        let dataSets = getLineChartDataSet(chartDataList: sessionChartData)
        let data = LineChartData(dataSets: dataSets)
        data.setValueFont(.systemFont(ofSize: 7, weight: .light))
        chartView.data = data
    }

    func getChartDataPoints(xAxixValues: [Double], dataValues: [Double]) -> [ChartDataEntry] {
        var dataPoints: [ChartDataEntry] = []
        for count in (0..<xAxixValues.count) {
            dataPoints.append(ChartDataEntry.init(x: xAxixValues[count], y: dataValues[count]))
        }
        return dataPoints
    }

    func getLineChartDataSet(chartDataList: [SessionChartData]) -> [LineChartDataSet] {
        var xValues: [Double] = []
        var uploadDataList: [Double] = []
        var downloadDataList: [Double] = []
        
        for (index, data) in chartDataList.enumerated() {
            xValues.append(Double(index))
            uploadDataList.append(data.dataValueUp)
            downloadDataList.append(data.dataValueDown)
            
        }
        
        let uploadDataPoints = getChartDataPoints(xAxixValues: xValues, dataValues: uploadDataList)
        let uploadDataSet = LineChartDataSet(entries: uploadDataPoints, label: "Upload")
        uploadDataSet.lineWidth = 2.5
        uploadDataSet.circleRadius = 4
        uploadDataSet.circleHoleRadius = 2
        let uploadDataColor = ChartColorTemplates.vordiplom()[3]
        uploadDataSet.setColor(uploadDataColor)
        uploadDataSet.setCircleColor(uploadDataColor)
        
        let downloadDataPoints = getChartDataPoints(xAxixValues: xValues, dataValues: downloadDataList)
        let downloadDataSet = LineChartDataSet(entries: downloadDataPoints, label: "Download")
        downloadDataSet.lineWidth = 2.5
        downloadDataSet.circleRadius = 4
        downloadDataSet.circleHoleRadius = 2
        let downloadDataColor = ChartColorTemplates.vordiplom()[4]
        downloadDataSet.setColor(downloadDataColor)
        downloadDataSet.setCircleColor(downloadDataColor)
        return [uploadDataSet, downloadDataSet]
    }
    
//    class Coordinator : NSObject {
//
//        var parent: LineChartSwiftUI
//
//        init(lineChartSwiftUI: LineChartSwiftUI) {
//            self.parent = lineChartSwiftUI
//        }
//    }
    
}

struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard().environmentObject(UserData())
    }
}
