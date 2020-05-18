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
    var billPaymentHelper: BillPaymentHelper
    var objectWillChange = PassthroughSubject<Bool, Never>()
    
    private var fosterGetUrlSubscriber: AnyCancellable? = nil
    private var fosterStatusSubscriber: AnyCancellable? = nil
    private var fosterRechargeSaveSubscriber: AnyCancellable? = nil
    private var getBkashTokenSubscriber: AnyCancellable? = nil
    private var createBkashPaymentSubscriber: AnyCancellable? = nil
    private var executeBkashPaymentSubscriber: AnyCancellable? = nil
    private var finishBkashPaymentSubscriber: AnyCancellable? = nil
    
    var showLoader = PassthroughSubject<Bool, Never>()
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var warningToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var paymentOptionsModalPublisher = PassthroughSubject<Bool, Never>()
    var fosterWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var bkashWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var showFosterWebViewPublisher = PassthroughSubject<Bool, Never>()
    var showBkashWebViewPublisher = PassthroughSubject<Bool, Never>()
    var bkashCreatePaymentPublisher = PassthroughSubject<String, Never>()
    var bkashPaymentStatusPublisher = PassthroughSubject<(Bool, String), Never>()
    
    // MARK: - init()
    init(billPaymentHelper: BillPaymentHelper) {
        self.billPaymentHelper = billPaymentHelper
    }
    
    // MARK: - deinit()
    deinit {
        fosterGetUrlSubscriber?.cancel()
        fosterStatusSubscriber?.cancel()
        fosterRechargeSaveSubscriber?.cancel()
        getBkashTokenSubscriber?.cancel()
        createBkashPaymentSubscriber?.cancel()
        executeBkashPaymentSubscriber?.cancel()
        finishBkashPaymentSubscriber?.cancel()
    }
    
    // MARK: - getBkashToken()
    // This function gets bkash payment token
    func getBkashToken() {
        self.getBkashTokenSubscriber = self.executeGetBkashTokenApiCall()?
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
                self.showBkashWebViewPublisher.send(true)
            })
    }
    
    func executeGetBkashTokenApiCall() -> AnyPublisher<BKashTokenResponse, Error>? {
        guard let userId = UserLocalStorage.getLoggedUserData()?.userID else {
            self.errorToastPublisher.send((true, "Payment can't be processed at this time, please try again!"))
            return nil
        }
        
        let jsonObject = ["invId": billPaymentHelper.invoiceId, "id": billPaymentHelper.userPackServiceId, "rechargeAmount": billPaymentHelper.balanceAmount, "loggedUserId": userId] as [String : Any]
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
    
    func paymentCancellation(message: String) {
        self.errorToastPublisher.send((true, message))
        self.showBkashWebViewPublisher.send(false)
        self.showLoader.send(false)
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
                        self.paymentCancellation(message: "Payment cancelled!, please try again later")
                }
            }, receiveValue: { response in
                guard let resBkash = response.resdata?.resbKash else {
                    self.paymentCancellation(message: response.resdata?.message ?? "Payment cancelled!, please try again later")
                    return
                }
                if !resBkash.isEmpty {
                    self.bkashCreatePaymentPublisher.send(resBkash)
                } else {
                    self.paymentCancellation(message: response.resdata?.message ?? "Payment cancelled!, please try again later")
                }
            })
    }
    
    func createBkashPaymentApiCall() -> AnyPublisher<BKashCreatePaymentResponse, Error>? {
        guard let token = bkashTokenModel?.idtoken, let currency = bkashTokenModel?.currency, let marchantInvNo = bkashTokenModel?.marchantInvNo else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        let jsonObject = ["authToken": token,
                          "rechargeAmount": billPaymentHelper.balanceAmount,
                          "Name": "sale",
                          "currency": currency,
                          "mrcntNumber": marchantInvNo] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/createbkashpayment") else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
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
                        self.paymentCancellation(message: "Payment cancelled!, please try again later")
                }
            }, receiveValue: { response in
                guard let resExecuteBk = response.resdata?.resExecuteBk else {
                    self.paymentCancellation(message: "Payment cancelled!, please try again later")
                    return
                }
                if !resExecuteBk.isEmpty {
                    self.saveBkashPayment(bkashPaymentResponse: resExecuteBk)
                } else {
                    self.paymentCancellation(message: "Payment cancelled!, please try again later")
                }
            })
    }
    
    func executeBkashPaymentApiCall() -> AnyPublisher<BKashExecutePaymentResponse, Error>? {
        
        guard let data = bkashTokenModel?.token?.data(using: .utf8) else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let tokenJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any], let token = tokenJson["id_token"], let paymentID = bkashPaymentExecuteJson["paymentID"] else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        let jsonObject = ["authToken": token,
                          "paymentID": paymentID] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/executebkashpayment") else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.paymentCancellation(message: "Payment cancelled!, please try again later")
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
    
    // MARK: - saveBkashPayment()
    // Saves the successful bkash payment data to server
    func saveBkashPayment(bkashPaymentResponse: String) {
        self.finishBkashPaymentSubscriber = self.saveBkashPaymentApiCall(bkashPaymentModel: bkashPaymentResponse)?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                        self.paymentCancellation(message: "Payment cancelled!, please contact with support team")
                }
            }, receiveValue: { response in
                guard let resstate = response.resdata?.resstate, let message = response.resdata?.message else {
                    self.bkashPaymentStatusPublisher.send((false, "Payment not successful, please contact with support team"))
                    return
                }
                self.bkashPaymentStatusPublisher.send((resstate, message))
            })
    }
    
    func saveBkashPaymentApiCall(bkashPaymentModel: String) -> AnyPublisher<DefaultResponse, Error>? {
        let bkashData = Data(bkashPaymentModel.utf8)
        guard let bkashJson = try? JSONSerialization.jsonObject(with: bkashData, options: .allowFragments) as? [String: Any] else {
            self.bkashPaymentStatusPublisher.send((false, "Payment not successful!, please contact with support team"))
            return nil
        }
        
        if let _ = bkashJson["errorCode"], let errorMessage = bkashJson["errorMessage"] {
            self.bkashPaymentStatusPublisher.send((false, "\(errorMessage)!"))
            return nil
        }
        
        let user = UserLocalStorage.getLoggedUserData()
        let loggedUser = UserLocalStorage.getUserCredentials().loggedUser
        guard let userId = user?.userID,
            let profileId = user?.profileID, let userTypeId = loggedUser?.userTypeId,
            let trxId = bkashJson["trxID"], let userName = user?.displayName else {
                self.bkashPaymentStatusPublisher.send((false, "Payment not successful!, please contact with support team"))
                return nil
        }
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let today = format.string(from: date)
        let jsonObject = ["BalanceAmount": billPaymentHelper.balanceAmount,
                          "DeductedAmount": billPaymentHelper.deductedAmount,
                          "ISPUserID": userId,
                          "InvoiceId": billPaymentHelper.invoiceId,
                          "IsActive": true,
                          "Particulars": "",
                          "ProfileId": profileId,
                          "RechargeType": "bkash",
                          "TransactionDate": today,
                          "TransactionNo": trxId,
                          "UserName": userName,
                          "UserPackServiceId": billPaymentHelper.userPackServiceId,
                          "UserTypeId": userTypeId] as [String : Any]
        
        let jsonArray = [jsonObject, bkashJson]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.bkashPaymentStatusPublisher.send((false, "Payment not successful!, please contact with support team"))
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/newrechargebkashpayment") else {
            self.bkashPaymentStatusPublisher.send((false, "Payment not successful!, please contact with support team"))
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.bkashPaymentStatusPublisher.send((false, "Payment not successful!, please contact with support team"))
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
                self.showFosterWebViewPublisher.send(true)
            })
    }
    
    func executeGetFosterUrlApiCall() -> AnyPublisher<FosterResponse, Error>? {
        
        guard let userId = UserLocalStorage.getLoggedUserData()?.userID else {
            self.errorToastPublisher.send((true, "Payment cancelled!, please try again later"))
            return nil
        }
        
        let jsonObject = ["UserID": userId, "rechargeAmount": billPaymentHelper.balanceAmount, "IsActive": true ] as [String : Any]
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
    
    func cancelFosterPayment(message: String) {
        self.showFosterWebViewPublisher.send(false)
        self.errorToastPublisher.send((true, message))
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
                guard let fosterRes = response.resdata.fosterRes else {
                    self.cancelFosterPayment(message: "Payment cancelled!, please try again later")
                    return
                }
                self.saveFosterRecharge(fosterModel: fosterRes)
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
    
    // MARK: - saveFosterRecharge()
    // Saves successful foster payment data
    func saveFosterRecharge(fosterModel: String) {
        self.fosterRechargeSaveSubscriber = self.executeFosterRechargeSaveApiCall(fosterModel: fosterModel)?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                        self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
                }
            }, receiveValue: { response in
                guard let resstate = response.resdata?.resstate else {
                    self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
                    return
                }
                if resstate == true {
                    self.successToastPublisher.send((true, response.resdata?.message ?? "Payment successful"))
                    self.showFosterWebViewPublisher.send(false)
                } else {
                    self.cancelFosterPayment(message: response.resdata?.message ?? "Payment not success, Please contact with support team!")
                }
            })
    }
    
    func executeFosterRechargeSaveApiCall(fosterModel: String) -> AnyPublisher<DefaultResponse, Error>? {
        
        let fosterData = Data(fosterModel.utf8)
        guard let fosterResponseModelArray = try? JSONDecoder().decode([FosterModel].self, from: fosterData) else {
            self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
            return nil
        }
        guard fosterResponseModelArray.count > 0 else {
            self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
            return nil
        }
        let fosterResponseModel = fosterResponseModelArray[0]
        let user = UserLocalStorage.getLoggedUserData()
        let loggedUser = UserLocalStorage.getUserCredentials().loggedUser
        
        guard let userId = user?.userID, let profileId = user?.profileID,
            let userTypeId = loggedUser?.userTypeId, let merchantTxnNo = fosterResponseModel.MerchantTxnNo,
            let userName = user?.displayName else {
                self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
                return nil
        }
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let today = format.string(from: date)
        let jsonObject = ["BalanceAmount": billPaymentHelper.balanceAmount,
                          "DeductedAmount": billPaymentHelper.deductedAmount,
                          "ISPUserID": userId,
                          "InvoiceId": billPaymentHelper.invoiceId,
                          "IsActive": true,
                          "Particulars": "",
                          "ProfileId": profileId,
                          "RechargeType": "foster",
                          "TransactionDate": today,
                          "TransactionNo": merchantTxnNo,
                          "UserName": userName,
                          "UserPackServiceId": billPaymentHelper.userPackServiceId,
                          "UserTypeId": userTypeId] as [String : Any]
        
        guard let fosterJsonData = try? JSONEncoder().encode(fosterResponseModel) else {
            self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
            return nil
        }
        let fosterJsonObject = try? JSONSerialization.jsonObject(with: fosterJsonData, options: .allowFragments) as? [String: Any?]
        
        let jsonArray = [jsonObject, fosterJsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl + "/api/ispportal/newrechargesave"), let url = urlComponents.url else {
            self.cancelFosterPayment(message: "Payment not successful!, Please contact with support team")
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
