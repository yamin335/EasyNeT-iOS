//
//  PGWViewModel.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 5/18/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import Combine

class PGWViewModel: ObservableObject {

    // MARK: - Properties
    var fosterHelper: FosterHelper? = nil
    var bkashPaymentExecuteJson: [String: Any] = [:]
    var bkashTokenModel: TModel? = nil
    var paymentRequest: PaymentRequest? = nil
    var billPaymentHelper: BillPaymentHelper? = nil
    var resExecuteBk = ""
    
    private var fosterGetUrlSubscriber: AnyCancellable? = nil
    private var fosterStatusSubscriber: AnyCancellable? = nil
    private var getBkashTokenSubscriber: AnyCancellable? = nil
    private var createBkashPaymentSubscriber: AnyCancellable? = nil
    private var executeBkashPaymentSubscriber: AnyCancellable? = nil
    
    var showLoader = PassthroughSubject<Bool, Never>()
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var warningToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var fosterWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var fosterPaymentStatusPublisher = PassthroughSubject<(Bool, String), Never>()
    var bkashWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var bkashCreatePaymentPublisher = PassthroughSubject<String, Never>()
    var bkashPaymentFinishPublisher = PassthroughSubject<Bool, Never>()
    var bkashPaymentStatusPublisher = PassthroughSubject<(Bool, BkashResData?), Never>()
    var objectWillChange = PassthroughSubject<Bool, Never>()
    var showPGW = PassthroughSubject<(Bool, PGW), Never>()
    
    
    // MARK: - deinit()
    deinit {
        fosterGetUrlSubscriber?.cancel()
        fosterStatusSubscriber?.cancel()
        getBkashTokenSubscriber?.cancel()
        createBkashPaymentSubscriber?.cancel()
        executeBkashPaymentSubscriber?.cancel()
    }
    
    func cancelBkashPayment(message: String) {
        self.bkashTokenModel = nil
        self.billPaymentHelper = nil
        self.errorToastPublisher.send((true, message))
        self.showLoader.send(false)
        self.showPGW.send((false, .BKASH))
        self.bkashPaymentStatusPublisher.send((false, nil))
    }
    
    func cancelFosterPayment(message: String) {
        self.fosterHelper = nil
        self.billPaymentHelper = nil
        self.errorToastPublisher.send((true, message))
        self.showLoader.send(false)
        self.showPGW.send((false, .FOSTER))
        self.fosterPaymentStatusPublisher.send((false, ""))
    }
    
    // MARK: - getBkashToken()
    // This function gets bkash payment token
    func getBkashToken() {
        self.getBkashTokenSubscriber = self.getBkashTokenApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                        self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
                }
            }, receiveValue: { response in
                guard let tModel = response.resdata?.tModel else {
                    self.errorToastPublisher.send((true, "Payment can't be processed at this time, please try again!"))
                    return
                }
                self.bkashTokenModel = tModel
                self.showPGW.send((true, .BKASH))
            })
    }
    
    func getBkashTokenApiCall() -> AnyPublisher<BKashTokenResponse, Error>? {
        guard let userId = UserLocalStorage.getLoggedUserData()?.userID, let helper = billPaymentHelper else {
            self.errorToastPublisher.send((true, "Payment can't be processed at this time, please try again!"))
            return nil
        }
        
        let jsonObject = ["invId": helper.invoiceId, "id": helper.userPackServiceId, "rechargeAmount": helper.balanceAmount, "deductedAmount": helper.deductedAmount, "loggedUserId": userId] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
            return nil
        }
        
        guard let params = String(data: jsonData, encoding: String.Encoding.ascii) else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/generatebkashtoken") else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
            return nil
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
            return nil
        }
        
        var request = getCommonUrlRequest(url: url)
        request.httpMethod = "GET"
        
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
        .decode(type: BKashTokenResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - createBkashPayment()
    // This function is called for creating bkash payment
    func createBkashPayment() {
        self.createBkashPaymentSubscriber = self.createBkashPaymentApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                        self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
                }
            }, receiveValue: { response in
                guard let resBkash = response.resdata?.resbKash else {
                    self.cancelBkashPayment(message: response.resdata?.message ?? "Payment cancelled!, please try again later")
                    return
                }
                if !resBkash.isEmpty {
                    self.bkashCreatePaymentPublisher.send(resBkash)
                } else {
                    self.cancelBkashPayment(message: response.resdata?.message ?? "Payment cancelled!, please try again later")
                }
            })
    }
    
    func createBkashPaymentApiCall() -> AnyPublisher<BKashCreatePaymentResponse, Error>? {
        guard let helper = billPaymentHelper, let token = bkashTokenModel?.idtoken, let currency = bkashTokenModel?.currency, let marchantInvNo = bkashTokenModel?.marchantInvNo else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        let jsonObject = ["authToken": token,
                          "rechargeAmount": helper.balanceAmount,
                          "deductedAmount": helper.deductedAmount,
                          "Name": "sale",
                          "currency": currency,
                          "mrcntNumber": marchantInvNo,
                          "canModify": helper.canModify
            ] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/createbkashpayment") else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
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
        .decode(type: BKashCreatePaymentResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - executeBkashPayment()
    // This function is called for executing bkash payment
    func executeBkashPayment() {
        self.executeBkashPaymentSubscriber = self.executeBkashPaymentApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                        self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
                }
            }, receiveValue: { response in
                guard let resExecuteBk = response.resdata?.resExecuteBk, !resExecuteBk.isEmpty else {
                    self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
                    return
                }
                
                self.resExecuteBk = resExecuteBk
                self.bkashPaymentFinishPublisher.send(true)
            })
    }
    
    func executeBkashPaymentApiCall() -> AnyPublisher<BKashExecutePaymentResponse, Error>? {
        
        guard let data = bkashTokenModel?.token?.data(using: .utf8), let marchantInvNo = bkashTokenModel?.marchantInvNo else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let tokenJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any], let token = tokenJson["id_token"], let paymentID = bkashPaymentExecuteJson["paymentID"] else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        let jsonObject = ["authToken": token,
                          "mrcntNumber": marchantInvNo,
                          "paymentID": paymentID] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/executebkashpayment") else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.cancelBkashPayment(message: "Payment cancelled!, please try again later")
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
        .decode(type: BKashExecutePaymentResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - getFosterPaymentUrl()
    // Gets url for foster payment
    func getFosterPaymentUrl() {
        self.fosterGetUrlSubscriber = self.executeGetFosterUrlApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                        self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
                }
            }, receiveValue: { response in
                guard let processUrl = response.resdata.paymentProcessUrl, let statusUrl = response.resdata.paymentStatusUrl else {
                    self.errorToastPublisher.send((true, response.resdata.message ?? "Payment can not be done at this moment, Please try again later!"))
                    return
                }
                self.fosterHelper = FosterHelper(fosterProcessUrl: processUrl, fosterStatusUrl: statusUrl)
                self.showPGW.send((true, .FOSTER))
            })
    }
    
    func executeGetFosterUrlApiCall() -> AnyPublisher<FosterResponse, Error>? {
        
        guard let helper = billPaymentHelper, let userId = UserLocalStorage.getLoggedUserData()?.userID else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
            return nil
        }
        
        let jsonObject = ["UserID": userId, "rechargeAmount": helper.balanceAmount, "deductedAmount": helper.deductedAmount ] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/isprecharge"), let url = urlComponents.url else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
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
        .decode(type: FosterResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - checkFosterStatus()
    // Checks that the foster payment has done successfully or not
    func checkFosterStatus() {
        self.fosterStatusSubscriber = self.executeFosterStatusApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                guard let fosterRes = response.resdata.fosterRes, !fosterRes.isEmpty else {
                    self.cancelFosterPayment(message: "Payment cancelled!, please try again later")
                    return
                }
                self.showPGW.send((false, .FOSTER))
                self.fosterPaymentStatusPublisher.send((true, fosterRes))
            })
    }
    
    func executeFosterStatusApiCall() -> AnyPublisher<FosterStatusCheckModel, Error>? {
        guard let statusUrl = fosterHelper?.fosterStatusUrl else {
            self.cancelFosterPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        let jsonObject = ["statusCheckUrl": statusUrl]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.cancelFosterPayment(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/isprechargesave"), let url = urlComponents.url else {
            self.cancelFosterPayment(message: "Payment cancelled!, please try again later")
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
        .decode(type: FosterStatusCheckModel.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
}
