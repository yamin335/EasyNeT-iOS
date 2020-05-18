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
    @State var showChartChangeModal = false
    @State var showModalBackGround = false
    @State private var selectedType = 0
    @State private var selectedMonth = 0
    @State private var showLoader = false
    var monthOptionsValue = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    var monthOptions = ["January", "February", "March", "April", "May", "June", "July", "August",  "September", "October", "November", "December"]
    var typeOptionsValue = ["monthly", "daily", "hourly"]
    var typeOptions = ["Monthly", "Daily", "Hourly"]
    
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
    
//    var shortCutMenu: some View {
//        GeometryReader { window in
//
//            //.background(Color.green)
//        }
//    }
    
    var modalBackground: some View {
        VStack {
            Rectangle().background(Color.black).blur(radius: 0.5, opaque: false).opacity(0.3)
        }
        .zIndex(1)
        .transition(.asymmetric(insertion: .opacity, removal: .opacity)).animation(.default)
        .onTapGesture {
            withAnimation {
                self.showChartChangeModal = false
                self.showModalBackGround = false
                self.dashboardViewModel.restoreModalState()
            }
        }
    }
    
    var chartChangeModal: some View {
        GeometryReader { geometry in
            VStack() {
                Spacer()
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                if self.showChartChangeModal == true {
                                    self.showChartChangeModal = false
                                    self.showModalBackGround = false
                                    self.dashboardViewModel.restoreModalState()
                                }
                            }
                        }) {
                            Text("Cancel")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.blue)
                                .padding(.leading, 20)
                        }
                        Spacer()
                        Text("Filter By")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundColor(Colors.color2)
                            .padding()
                        Spacer()
                        Button(action: {
                            withAnimation {
                                if self.showChartChangeModal == true {
                                    self.dashboardViewModel.sessionChartData = [SessionChartData]()
                                    self.dashboardViewModel.sessionChartDataPublisher.send(false)
                                    self.showChartChangeModal = false
                                    self.showModalBackGround = false
                                    self.dashboardViewModel.getSessionChartData(month: self.monthOptionsValue[self.selectedMonth], type: self.typeOptionsValue[self.selectedType])
                                }
                            }
                        }) {
                            Text("Done")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.blue)
                                .padding(.trailing, 20)
                        }
                    }
                    
                    Divider()
                    
                    Picker(selection: self.$selectedType, label: Text("Type:")
                        .frame(minWidth: 50)) {
                            ForEach(0 ..< self.typeOptions.count) {
                                Text(self.typeOptions[$0])
                                
                            }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.leading, 20)
                    .padding(.trailing, 20).padding(.top, 20)
                    
                    Picker(selection: self.$selectedMonth, label: Text("Month:")
                        .frame(minWidth: 60)) {
                            ForEach(0 ..< self.monthOptions.count) {
                                Text(self.monthOptions[$0])
                                
                            }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(minWidth: 0, maxWidth: geometry.size.width - 60)
                    .padding(.leading, 30)
                    .padding(.trailing, 30)
                    
                    
                }
                .background(ChatBubble(fillColor: Color.white, topLeft: 10, topRight: 10, bottomLeft: 0, bottomRight: 0))
            }
        }.zIndex(2)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .onAppear {
            withAnimation {
                self.showModalBackGround = true
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom))).animation(.default)
        
        
    }
    
    var chartHeader: some View {
        HStack(spacing: 4) {
            Text("\(typeOptions[selectedType]) Data Traffic in:")
                .foregroundColor(Colors.color2)
                .padding(.leading, 16)
//                .contextMenu {
//                Button(action: {
//                    // change country setting
//                }) {
//                    Text("Choose Country")
//                    Image(systemName: "globe")
//                }
//
//                Button(action: {
//                    // enable geolocation
//                }) {
//                    Text("Detect Location")
//                    Image(systemName: "location.circle")
//                }
//            }
            
            Text(monthOptions[selectedMonth]).fontWeight(.semibold).foregroundColor(Colors.color2)
            
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "gear")
                    .font(.system(size: 16, weight: .bold))
                    .imageScale(.large)
                    .foregroundColor(Colors.color6)
                    .padding(.leading, 8)
                
                Text("Change")
                    .foregroundColor(Colors.greenTheme)
                    .padding(.trailing, 16)
                
            }.onTapGesture {
                withAnimation {
                    if self.showChartChangeModal == false {
                        self.dashboardViewModel.tempTypeindex = self.selectedType
                        self.dashboardViewModel.tempMonthIndex = self.selectedMonth
                        self.showChartChangeModal = true
                    }
                }
            }
        }.padding(.bottom, 12).padding(.top, 12)
    }
    
    var chartView: some View {
        ZStack(alignment: .bottom) {
            if self.showSessionChart {
                VStack {
                    Spacer()
                    LineChartSwiftUI(viewModel: self.dashboardViewModel)
                }
            } else {
                Text("No Session Data Found")
                    .foregroundColor(Colors.color3)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
//                    self.shortCutMenu.frame(minWidth: 0, maxWidth: .infinity)
                    Group {
                        VStack(alignment: .center) {
                            HStack(alignment: .top) {
                                Spacer()
                                VStack {
                                    Image("my_account")
                                        .resizable()
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20), height: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                        
                                    Text("My Account")
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.center)
                                }
                                //.padding(.top, 30)
                                .onTapGesture {
                                    self.userData.selectedTabItem = 1
                                }
                                Spacer()
                                VStack {
                                    Image("pay_now")
                                        .resizable()
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20), height: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                      
                                    Text("Pay Now")
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.center)
                                }
                                //.padding(.top, 30)
                                .onTapGesture {
                                    self.userData.selectedTabItem = 2
                                }
                                Spacer()
                                VStack {
                                    Image("pay_history")
                                        .resizable()
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20), height: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                      
                                    Text("Bill History")
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.center)
                                }
                                //.padding(.top, 30)
                                .onTapGesture {
                                    self.userData.selectedTabItem = 2
                                }
                                Spacer()
                            }
                            Spacer()
                            
                            HStack(alignment: .top) {
                                Spacer()
                                VStack {
                                    Image("packages")
                                        .resizable()
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20), height: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                      
                                    Text("Packages")
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                }
                                .onTapGesture {
                                    self.userData.selectedTabItem = 1
                                }
                                Spacer()
                                VStack {
                                    Image("open_ticket")
                                        .resizable()
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20), height: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                        
                                    Text("Open Ticket")
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
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
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20), height: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                      
                                    Text("Ticket History")
                                        .frame(width: self.getImageSize(width: geometry.size.width, height: (geometry.size.height / 2) - 20))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.center)
                                }
                                .onTapGesture {
                                    self.userData.selectedTabItem = 3
                                }
                                Spacer()
                            }
                            Spacer()
                        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: (geometry.size.height / 2) - 20)
                    }
                    
                    self.chartHeader.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 40)

                    self.chartView.frame(width: geometry.size.width - 18, height: (geometry.size.height/2) - 40)
                    
                }.onReceive(self.dashboardViewModel.typeIndexPublisher.receive(on: RunLoop.main)) { value in
                    self.selectedType = value
                }
                .onReceive(self.dashboardViewModel.monthIndexPublisher.receive(on: RunLoop.main)) { value in
                    self.selectedMonth = value
                }
                .onReceive(self.dashboardViewModel.sessionChartDataPublisher.receive(on: RunLoop.main)) { value in
                    
                    if value {
                        self.showSessionChart = true
                    } else {
                        self.showSessionChart = false
                    }
                }
                .onReceive(self.dashboardViewModel.showLoader.receive(on: RunLoop.main)) { shouldShow in
                    self.showLoader = shouldShow
                }
                .onAppear() {
                    let date = Date()
                    let dateFormatter = DateFormatter()
                    let calendar = dateFormatter.calendar
                    guard let month = calendar?.component(.month, from: date) else {
                        return
                    }
                    self.dashboardViewModel.getSessionChartData(month: month, type: "daily")
                    self.dashboardViewModel.typeIndexPublisher.send(1)
                    self.dashboardViewModel.monthIndexPublisher.send(month - 1)
                }.onDisappear() {
                    self.showSessionChart = false
                }
                
                if self.showModalBackGround {
                    self.modalBackground
                }
                
                if self.showChartChangeModal {
                    self.chartChangeModal
                }
                
                if self.showLoader {
                    SpinLoaderView()
                }
            }
        }
    }
    
    func getImageSize(width: CGFloat, height: CGFloat) -> CGFloat {
        let tempWidth = (width - 4*20)/3
        let tempHeight = (height - 4*20)/2
        return tempWidth > tempHeight ? tempHeight : tempWidth
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
        lineChartView.animate(xAxisDuration: 0.7)
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
        uploadDataSet.mode = LineChartDataSet.Mode.cubicBezier
        
        let downloadDataPoints = getChartDataPoints(xAxixValues: xValues, dataValues: downloadDataList)
        let downloadDataSet = LineChartDataSet(entries: downloadDataPoints, label: "Download")
        downloadDataSet.lineWidth = 2.5
        downloadDataSet.circleRadius = 4
        downloadDataSet.circleHoleRadius = 2
        let downloadDataColor = ChartColorTemplates.vordiplom()[4]
        downloadDataSet.setColor(downloadDataColor)
        downloadDataSet.setCircleColor(downloadDataColor)
        downloadDataSet.mode = LineChartDataSet.Mode.cubicBezier
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
