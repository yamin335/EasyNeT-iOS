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
    private var logoutSubscriber: AnyCancellable? = nil
    
    @Published var oldPassword = ""
    @Published var newPassword = ""
    @Published var newConfPassword = ""
    let userCredentials = UserLocalStorage.getUserCredentials()
    var showLoader = PassthroughSubject<Bool, Never>()
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var signoutPublisher = PassthroughSubject<Bool, Never>()
    
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
        logoutSubscriber?.cancel()
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
                if let resdata = response.resdata {
                    self.successToastPublisher.send((true, resdata.message ?? "Password Successfully Changed"))
                } else {
                    self.errorToastPublisher.send((true, "Not Successful"))
                }
            })
    }
    
    func executeChangePasswordApiCall() -> AnyPublisher<DefaultResponse, Error>? {

        let userCredentials = UserLocalStorage.getUserCredentials()
        let jsonObject = ["password": newPassword,
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
    
    func logOut() {
        self.logoutSubscriber = self.executeLogoutApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                if let resstate = response.resdata?.resstate {
                    if resstate == true {
                        self.successToastPublisher.send((true, response.resdata?.message ?? "Signed Out Successfully"))
                    } else {
                        self.errorToastPublisher.send((true, response.resdata?.message ?? "Not Successful, Please Try Again!"))
                    }
                    self.signoutPublisher.send(resstate)
                }
            })
    }
    
    func executeLogoutApiCall() -> AnyPublisher<DefaultResponse, Error>? {

        let loggedUser = UserLocalStorage.getUserCredentials().loggedUser
        let authToken = loggedUser?.ispToken ?? ""
        let userId = loggedUser?.userID ?? 0
        let jsonObject = ["userId": userId,
                          "values": authToken] as [String : Any]
        
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl + "/api/ispportal/loggedout") else {
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
}
