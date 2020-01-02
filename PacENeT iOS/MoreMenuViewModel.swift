//
//  MoreMenuViewModel.swift
//  PacENeT iOS
//
//  Created by rgl on 31/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import Foundation
import Combine

class MoreMenuViewModel: ObservableObject {
    private var changePassSubscriber: AnyCancellable? = nil
//    private var osSummarySubscriber: AnyCancellable? = nil
//    var showLoader = PassthroughSubject<Bool, Never>()
//    var osStatusDataPublisher = PassthroughSubject<[PieChartData], Never>()
//    var osSummaryDataPublisher = PassthroughSubject<[BarChartData], Never>()
    
    @Published var oldPassword = ""
    @Published var newPassword = ""
    @Published var newConfPassword = ""
    let userCredentials = UserLocalStorage.getUserCredentials()
    var showLoader = PassthroughSubject<Bool, Never>()
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    
    var isChangePassFormValid: AnyPublisher<Int?, Never> {
        return Publishers.CombineLatest3($oldPassword, $newPassword, $newConfPassword)
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .map { oldPassword, newPassword, newConfPassword in
                print(oldPassword, newPassword, newConfPassword)
                if !oldPassword.isEmpty && oldPassword != self.userCredentials.password {
                    return 1
                }
                
                if !oldPassword.isEmpty && !newPassword.isEmpty && oldPassword == newPassword {
                    return 2
                }
                
                if !newPassword.isEmpty && (newPassword.count < 5 || newPassword.count > 24)  {
                    return 3
                }
                
                if !newPassword.isEmpty && !newConfPassword.isEmpty && newPassword != newConfPassword {
                    return 4
                }
                
                guard !oldPassword.isEmpty, !newPassword.isEmpty,
                    !newConfPassword.isEmpty, oldPassword == self.userCredentials.password,
                    oldPassword != newPassword, newPassword == newConfPassword,
                    newPassword.count >= 5, newPassword.count <= 24 else { return nil }
                return 5
        }
        .eraseToAnyPublisher()
    }
    
    deinit {
        changePassSubscriber?.cancel()
//        osSummarySubscriber?.cancel()
    }
    
    func changePassword() {
        self.changePassSubscriber = self.executeChangePasswordApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                if let resstate = response.resdata.resstate {
                    if resstate == true {
                        self.successToastPublisher.send((true, response.resdata.message ?? "Password Successfully Changed"))
                    } else {
                        self.errorToastPublisher.send((true, response.resdata.message ?? "Not Successful"))
                    }
                }
            })
    }
    
    func executeChangePasswordApiCall() -> AnyPublisher<DefaultResponse, Error>? {

        let userCredentials = UserLocalStorage.getUserCredentials()
        let jsonObject = ["passowrd": newPassword,
                          "userName": userCredentials.userName,
                          "oldPassword": oldPassword] as [String : Any?]
        
        let jsonArray = [jsonObject]
        if !JSONSerialization.isValidJSONObject(jsonArray) {
            print("Problem in parameter creation...")
            return nil
        }
        
        let tempJson = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
        
        guard let jsonData = tempJson else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl + "/api/ispportal/changepassword") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        //Request type
        var request = getCommonUrlRequest(url: url)
        request.httpMethod = "POST"
        
        //Setting headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Setting body for POST request
        request.httpBody = jsonData
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .handleEvents(receiveSubscription: { _ in
                self.showLoader.send(true)
            }, receiveOutput: { _ in
                self.showLoader.send(false)
            }, receiveCompletion: { _ in
                self.showLoader.send(false)
            }, receiveCancel: {
                self.showLoader.send(false)
            })
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NetworkApiService.APIFailureCondition.InvalidServerResponse
                }
                
                return data
        }
        .retry(1)
        .decode(type: DefaultResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
//    func getOsStatus() {
//        self.osStatusSubscriber = self.executeOsStatusApiCall()?
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                    case .finished:
//                        break
//                    case .failure(let error):
//                        print(error.localizedDescription)
//                    //                        fatalError(error.localizedDescription)
//                }
//            }, receiveValue: { response in
//                self.osStatusDataPublisher.send(response.resdata.dashboardchartdata)
//            })
//    }
//
//    func executeOsStatusApiCall() -> AnyPublisher<OSStatusModel, Error>? {
//        let user = UserLocalStorage.getUser()
//        let jsonObject = ["CompanyID": user.companyID ?? 0, "values": "cloudvmstatus", "UserID": user.userID ?? 0] as [String : Any]
//        let jsonArray = [jsonObject]
//        if !JSONSerialization.isValidJSONObject(jsonArray) {
//            print("Problem in parameter creation...")
//            return nil
//        }
//        let tempJson = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
//        guard let jsonData = tempJson else {
//            print("Problem in parameter creation...")
//            return nil
//        }
//        let tempParams = String(data: jsonData, encoding: String.Encoding.ascii)
//        guard let params = tempParams else {
//            print("Problem in parameter creation...")
//            return nil
//        }
//        var queryItems = [URLQueryItem]()
//
//        queryItems.append(URLQueryItem(name: "param", value: params))
//        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/portal/GetDashboardChartPortal") else {
//            print("Problem in UrlComponent creation...")
//            return nil
//        }
//        urlComponents.queryItems = queryItems
//
//        guard let url = urlComponents.url else {
//            return nil
//        }
//
//        var request = getCommonUrlRequest(url: url)
//        request.httpMethod = "GET"
//
//        return URLSession.shared.dataTaskPublisher(for: request)
//            .handleEvents(receiveSubscription: { _ in
//                self.showLoader.send(true)
//            }, receiveOutput: { _ in
//                self.showLoader.send(false)
//            }, receiveCompletion: { _ in
//                self.showLoader.send(false)
//            }, receiveCancel: {
//                self.showLoader.send(false)
//            })
//            .tryMap { data, response -> Data in
//                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                    throw NetworkApiService.APIFailureCondition.InvalidServerResponse
//                }
//
//                let string = String(data: data, encoding: .utf8)
//                print(string ?? "Undefined login data")
//                return data
//        }
//        .retry(1)
//        .decode(type: OSStatusModel.self, decoder: JSONDecoder())
//        .receive(on: RunLoop.main)
//        .eraseToAnyPublisher()
//    }
//
//    func getOsSummary() {
//        self.osSummarySubscriber = self.executeOsSummaryApiCall()?
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                    case .finished:
//                        break
//                    case .failure(let error):
//                        print(error.localizedDescription)
//                    //                        fatalError(error.localizedDescription)
//                }
//            }, receiveValue: { response in
//                self.osSummaryDataPublisher.send(response.resdata.dashboardchartdata)
//            })
//    }
//
//    func executeOsSummaryApiCall() -> AnyPublisher<OSSummaryModel, Error>? {
//        let user = UserLocalStorage.getUser()
//        let jsonObject = ["CompanyID": user.companyID ?? 0, "values": "cloudvm", "UserID": user.userID ?? 0] as [String : Any]
//        let jsonArray = [jsonObject]
//        if !JSONSerialization.isValidJSONObject(jsonArray) {
//            print("Problem in parameter creation...")
//            return nil
//        }
//        let tempJson = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
//        guard let jsonData = tempJson else {
//            print("Problem in parameter creation...")
//            return nil
//        }
//        let tempParams = String(data: jsonData, encoding: String.Encoding.ascii)
//        guard let params = tempParams else {
//            print("Problem in parameter creation...")
//            return nil
//        }
//        var queryItems = [URLQueryItem]()
//
//        queryItems.append(URLQueryItem(name: "param", value: params))
//        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/portal/GetDashboardChartPortal") else {
//            print("Problem in UrlComponent creation...")
//            return nil
//        }
//        urlComponents.queryItems = queryItems
//
//        guard let url = urlComponents.url else {
//            return nil
//        }
//
//        var request = getCommonUrlRequest(url: url)
//        request.httpMethod = "GET"
//
//        return URLSession.shared.dataTaskPublisher(for: request)
//            .handleEvents(receiveSubscription: { _ in
//                self.showLoader.send(true)
//            }, receiveOutput: { _ in
//                self.showLoader.send(false)
//            }, receiveCompletion: { _ in
//                self.showLoader.send(false)
//            }, receiveCancel: {
//                self.showLoader.send(false)
//            })
//            .tryMap { data, response -> Data in
//                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                    throw NetworkApiService.APIFailureCondition.InvalidServerResponse
//                }
//
//                let string = String(data: data, encoding: .utf8)
//                print(string ?? "Undefined login data")
//                return data
//        }
//        .retry(1)
//        .decode(type: OSSummaryModel.self, decoder: JSONDecoder())
//        .receive(on: RunLoop.main)
//        .eraseToAnyPublisher()
//    }
//
//    func refreshUI() {
//        getOsStatus()
//        getOsSummary()
//    }
}
