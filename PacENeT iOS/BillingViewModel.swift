//
//  BillingViewModel.swift
//  PacENeT iOS
//
//  Created by Yamin on 23/3/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import Combine

class BillingViewModel: ObservableObject {

    // MARK: - Properties
    @Published var paymentAmount: Double? = nil
    @Published var invoiceList = [Invoice]()
    @Published var invoiceDetailList = [InvoiceDetail]() {
        willSet {
            objectWillChange.send(true)
        }
    }
    @Published var payHistList = [PayHist]()
    @Published var userBalance: UserBalance? {
        willSet {
            objectWillChange.send(true)
        }
    }
    @Published var userPackServices = [UserPackService]() {
        didSet {
            objectWillChange.send(true)
        }
    }
    
    var fosterStatusUrl: String? = nil
    var fosterProcessUrl: String? = nil
    var bkashPaymentExecuteJson: [String: Any] = [:]
    
    var bkashTokenModel: TModel? = nil
    private var validDigits = CharacterSet(charactersIn: "1234567890.")
    
    var paymentRequest: PaymentRequest? = nil
    var payingUserPackServiceId: Int? = nil
    var payingInvoiceId: Int? = nil
    var invoicePageNumber = -1
    var payHistPageNumber = -1
    var objectWillChange = PassthroughSubject<Bool, Never>()
    
    private var fosterGetUrlSubscriber: AnyCancellable? = nil
    private var validAmountChecker: AnyCancellable? = nil
    private var fosterStatusSubscriber: AnyCancellable? = nil
    private var fosterRechargeSaveSubscriber: AnyCancellable? = nil
    private var getBkashTokenSubscriber: AnyCancellable? = nil
    private var createBkashPaymentSubscriber: AnyCancellable? = nil
    private var executeBkashPaymentSubscriber: AnyCancellable? = nil
    private var finishBkashPaymentSubscriber: AnyCancellable? = nil
    private var invoiceSubscriber: AnyCancellable? = nil
    private var invoiceDetailSubscriber: AnyCancellable? = nil
    private var payHistSubscriber: AnyCancellable? = nil
    private var userBalanceSubscriber: AnyCancellable? = nil
    private var userPackServiceSubscriber: AnyCancellable? = nil
    
    var showLoader = PassthroughSubject<Bool, Never>()
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var warningToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var paymentOptionsModalPublisher = PassthroughSubject<Bool, Never>()
    var okButtonDisablePublisher = PassthroughSubject<Bool, Never>()
    var fosterWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var bkashWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var showFosterWebViewPublisher = PassthroughSubject<Bool, Never>()
    var showBkashWebViewPublisher = PassthroughSubject<Bool, Never>()
    var bkashCreatePaymentPublisher = PassthroughSubject<String, Never>()
    var bkashPaymentStatusPublisher = PassthroughSubject<(Bool, String), Never>()
    
    // MARK: - deinit()
    deinit {
        fosterGetUrlSubscriber?.cancel()
        validAmountChecker?.cancel()
        fosterStatusSubscriber?.cancel()
        fosterRechargeSaveSubscriber?.cancel()
        getBkashTokenSubscriber?.cancel()
        createBkashPaymentSubscriber?.cancel()
        executeBkashPaymentSubscriber?.cancel()
        finishBkashPaymentSubscriber?.cancel()
        invoiceSubscriber?.cancel()
        invoiceDetailSubscriber?.cancel()
        payHistSubscriber?.cancel()
        userBalanceSubscriber?.cancel()
        userPackServiceSubscriber?.cancel()
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
        guard let userId = UserLocalStorage.getLoggedUserData()?.userID, let amount = paymentAmount else {
            self.errorToastPublisher.send((true, "Payment can't be processed at this time, please try again!"))
            return nil
        }
        
        let jsonObject = ["invId": payingInvoiceId ?? 0, "id": userId, "rechargeAmount": amount, "loggedUserId": userId] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let params = String(data: jsonData, encoding: String.Encoding.ascii) else {
            print("Problem in parameter creation...")
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/generatebkashtoken") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
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
                }
            }, receiveValue: { response in
                guard let resBkash = response.resdata?.resbKash else {
                    self.errorToastPublisher.send((true, "Can not create payment, please try again!"))
                    self.showBkashWebViewPublisher.send(false)
                    self.showLoader.send(false)
                    return
                }
                if !resBkash.isEmpty {
                    self.bkashCreatePaymentPublisher.send(resBkash)
                } else {
                    self.errorToastPublisher.send((true, response.resdata?.message ?? "Can not create payment, please try again!"))
                    self.showBkashWebViewPublisher.send(false)
                    self.showLoader.send(false)
                }
            })
    }
    
    func createBkashPaymentApiCall() -> AnyPublisher<BKashCreatePaymentResponse, Error>? {
        guard let token = bkashTokenModel?.idtoken else {
            return nil
        }
        
        guard let amount = paymentAmount, let currency = bkashTokenModel?.currency, let marchantInvNo = bkashTokenModel?.marchantInvNo else {
            return nil
        }
        
        let jsonObject = ["authToken": token,
                          "rechargeAmount": amount,
                          "Name": "sale",
                          "currency": currency,
                          "mrcntNumber": marchantInvNo] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/createbkashpayment") else {
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
                }
            }, receiveValue: { response in
                guard let resExecuteBk = response.resdata?.resExecuteBk else {
                    self.errorToastPublisher.send((true, "Can not execute payment, please try again!"))
                    return
                }
                if !resExecuteBk.isEmpty {
                    self.saveBkashPayment(bkashPaymentResponse: resExecuteBk)
                } else {
                    self.errorToastPublisher.send((true, "Can not execute payment, please try again!"))
                    self.showBkashWebViewPublisher.send(false)
                    self.showLoader.send(false)
                }
            })
    }
    
    func executeBkashPaymentApiCall() -> AnyPublisher<BKashExecutePaymentResponse, Error>? {
        
        guard let data = bkashTokenModel?.token?.data(using: .utf8) else {
            self.errorToastPublisher.send((true, "Can not create payment, please try again!"))
            return nil
        }
        
        guard let tokenJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            self.errorToastPublisher.send((true, "Can not create payment, please try again!"))
            return nil
        }
        
        guard let token = tokenJson["id_token"], let paymentID = bkashPaymentExecuteJson["paymentID"] else {
            return nil
        }
        
        let jsonObject = ["authToken": token,
                          "paymentID": paymentID] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/executebkashpayment") else {
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
                }
            }, receiveValue: { response in
                guard let resstate = response.resdata.resstate, let message = response.resdata.message else {
                    self.bkashPaymentStatusPublisher.send((false, "Can not save payment, please contact with support team!"))
                    return
                }
                self.bkashPaymentStatusPublisher.send((resstate, message))
                self.refreshUI()
            })
    }
    
    func saveBkashPaymentApiCall(bkashPaymentModel: String) -> AnyPublisher<DefaultResponse, Error>? {
        let bkashData = Data(bkashPaymentModel.utf8)
        guard let bkashJson = try? JSONSerialization.jsonObject(with: bkashData, options: .allowFragments) as? [String: Any] else {
            return nil
        }
        
        if let _ = bkashJson["errorCode"], let errorMessage = bkashJson["errorMessage"] {
            self.bkashPaymentStatusPublisher.send((false, "\(errorMessage)!"))
            return nil
        }
        
        let user = UserLocalStorage.getLoggedUserData()
        let loggedUser = UserLocalStorage.getUserCredentials().loggedUser
        guard let userId = user?.userID, let packServiceId = payingUserPackServiceId,
            let profileId = user?.profileID, let userTypeId = loggedUser?.userTypeId,
            let trxId = bkashJson["trxID"], let userName = user?.displayName,
            let amount = bkashJson["amount"] else {
                return nil
        }
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let today = format.string(from: date)
        let jsonObject = ["ISPUserID": userId,
                          "UserPackServiceId": packServiceId,
                          "ProfileId": profileId,
                          "UserTypeId": userTypeId,
                          "TransactionNo": trxId,
                          "InvoiceId": payingInvoiceId ?? 0,
                          "UserName": userName,
                          "TransactionDate": today,
                          "RechargeType": "bkash",
                          "BalanceAmount": amount,
                          "Particulars": "",
                          "IsActive": true] as [String : Any]
        
        let jsonArray = [jsonObject, bkashJson]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/newrechargebkashpayment") else {
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
                }
            }, receiveValue: { response in
                guard let processUrl = response.resdata.paymentProcessUrl, let statusUrl = response.resdata.paymentStatusUrl else {
                    self.errorToastPublisher.send((true, response.resdata.message ?? "Payment can not be done at this moment, Please try again later!"))
                    return
                }
                self.fosterStatusUrl = statusUrl
                self.fosterProcessUrl = processUrl
                self.showFosterWebViewPublisher.send(true)
            })
    }
    
    func executeGetFosterUrlApiCall() -> AnyPublisher<FosterResponse, Error>? {
        let user = UserLocalStorage.getLoggedUserData()
        guard let userId = user?.userID, let amount = paymentAmount else {
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
            return nil
        }
        let jsonObject = ["UserID": userId, "rechargeAmount": amount, "IsActive": true ] as [String : Any]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/isprecharge") else {
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
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
                guard let fosterRes = response.resdata.fosterRes else {
                    self.showFosterWebViewPublisher.send(false)
                    self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
                    return
                }
                self.saveFosterRecharge(fosterModel: fosterRes)
            })
    }
    
    func executeFosterStatusApiCall() -> AnyPublisher<FosterStatusCheckModel, Error>? {
        guard let statusUrl = fosterStatusUrl else {
            self.showFosterWebViewPublisher.send(true)
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
            return nil
        }
        let jsonObject = ["statusCheckUrl": statusUrl]
        let jsonArray = [jsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.showFosterWebViewPublisher.send(true)
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/isprechargesave") else {
            self.showFosterWebViewPublisher.send(true)
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.showFosterWebViewPublisher.send(true)
            self.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
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
                }
            }, receiveValue: { response in
                guard let resstate = response.resdata.resstate else {
                    self.showFosterWebViewPublisher.send(false)
                    self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
                    return
                }
                if resstate == true {
                    self.successToastPublisher.send((true, response.resdata.message ?? "Payment successful"))
                    self.refreshUI()
                } else {
                    self.errorToastPublisher.send((true, response.resdata.message ?? "Payment not success, Please contact with support team!"))
                }
                self.showFosterWebViewPublisher.send(false)
            })
    }
    
    func executeFosterRechargeSaveApiCall(fosterModel: String) -> AnyPublisher<DefaultResponse, Error>? {
        
        let fosterData = Data(fosterModel.utf8)
        guard let fosterResponseModelArray = try? JSONDecoder().decode([FosterModel].self, from: fosterData) else {
            self.showFosterWebViewPublisher.send(false)
            self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
            return nil
        }
        guard fosterResponseModelArray.count > 0 else {
            self.showFosterWebViewPublisher.send(false)
            self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
            return nil
        }
        let fosterResponseModel = fosterResponseModelArray[0]
        let user = UserLocalStorage.getLoggedUserData()
        let loggedUser = UserLocalStorage.getUserCredentials().loggedUser
        
        guard let userId = user?.userID, let profileId = user?.profileID, let packServiceId = payingUserPackServiceId,
            let userTypeId = loggedUser?.userTypeId, let merchantTxnNo = fosterResponseModel.MerchantTxnNo,
            let userName = user?.displayName, let amount = fosterResponseModel.TxnAmount else {
                self.showFosterWebViewPublisher.send(true)
                self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
                return nil
        }
        
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let today = format.string(from: date)
        let jsonObject = ["ISPUserID": userId,
                          "UserPackServiceId": packServiceId,
                          "ProfileId": profileId,
                          "UserTypeId": userTypeId,
                          "TransactionNo": merchantTxnNo,
                          "InvoiceId": payingInvoiceId ?? 0,
                          "UserName": userName,
                          "TransactionDate": today,
                          "RechargeType": "foster",
                          "BalanceAmount": amount,
                          "Particulars": "",
                          "IsActive": true] as [String : Any]
        
        guard let fosterJsonData = try? JSONEncoder().encode(fosterResponseModel) else {
            self.showFosterWebViewPublisher.send(false)
            self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
            return nil
        }
        let fosterJsonObject = try? JSONSerialization.jsonObject(with: fosterJsonData, options: .allowFragments) as? [String: Any?]
        
        let jsonArray = [jsonObject, fosterJsonObject]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            self.showFosterWebViewPublisher.send(false)
            self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl + "/api/ispportal/newrechargesave") else {
            self.showFosterWebViewPublisher.send(false)
            self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
            return nil
        }
        
        guard let url = urlComponents.url else {
            self.showFosterWebViewPublisher.send(false)
            self.errorToastPublisher.send((true, "Payment not success, Please contact with support team!"))
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
    
    // MARK: - getUserInvoiceList()
    // Gets user's all invoice
    func getUserInvoiceList() {
        self.invoiceSubscriber = self.executeInvoiceApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                    print(error.localizedDescription)
                }
            }, receiveValue: { response in
                guard let validResponse = response.resdata?.userinvoiceList else {
                    return
                }
                
                guard let responseData = validResponse.data(using: .utf8) else {
                    print("Problem in response data parsing...")
                    return
                }
                
                guard let invoicelist = try? JSONDecoder().decode([Invoice].self, from: responseData) else {
                    return
                }
                
                if invoicelist.count > 0 {
                    self.invoiceList.append(contentsOf: invoicelist)
                    self.objectWillChange.send(true)
                }
            })
    }
    
    func executeInvoiceApiCall() -> AnyPublisher<InvoiceResponse, Error>? {
        invoicePageNumber += 1
        let jsonObject = ["UserID": UserLocalStorage.getLoggedUserData()?.userID ?? 0, "pageNumber": invoicePageNumber, "pageSize": 30, "values": "", "SDate": "", "EDate": ""] as [String : Any]
        let jsonArray = [jsonObject]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
     
        guard let params = String(data: jsonData, encoding: String.Encoding.ascii) else {
            print("Problem in parameter creation...")
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/getallispinvbyusrid") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
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
        .decode(type: InvoiceResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - getUserInvoiceDetails()
    // Get user's specific invoice details
    func getUserInvoiceDetails(SDate: String, EDate: String, CDate: String, invId: Int, userPackServiceId: Int) {
        self.invoiceDetailSubscriber = self.executeInvoiceDetailApiCall(SDate: SDate, EDate: EDate, CDate: CDate, invId: invId, userPackServiceId: userPackServiceId)?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                    print(error.localizedDescription)
                }
            }, receiveValue: { response in
                guard let validResponse = response.resdata?.userinvoiceDetail else {
                    return
                }
                
                guard let responseData = validResponse.data(using: .utf8) else {
                    print("Problem in response data parsing...")
                    return
                }
                
                guard let invoiceDetailList = try? JSONDecoder().decode([InvoiceDetail].self, from: responseData) else {
                    return
                }
                
                if invoiceDetailList.count > 0 {
                    self.invoiceDetailList = invoiceDetailList
                }
            })
    }
    
    func executeInvoiceDetailApiCall(SDate: String, EDate: String, CDate: String, invId: Int, userPackServiceId: Int) -> AnyPublisher<InvoiceDetailResponse, Error>? {
        let jsonObject = ["SDate": SDate, "EDate": EDate, "CDate": CDate, "invId": invId, "IspUserID": UserLocalStorage.getLoggedUserData()?.userID ?? 0, "userPackServiceId": userPackServiceId] as [String : Any]
        let jsonArray = [jsonObject]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
    
        guard let params = String(data: jsonData, encoding: String.Encoding.ascii) else {
            print("Problem in parameter creation...")
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/getispuserinvocedetail") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
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
        .decode(type: InvoiceDetailResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - getUserPayHistory()
    // Gets user's all payment history
    func getUserPayHistory(value: String, SDate: String, EDate: String) {
        self.invoiceDetailSubscriber = self.executePayHistApiCall(value: value, SDate: SDate, EDate: EDate)?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                    print(error.localizedDescription)
                }
            }, receiveValue: { response in
                guard let validResponse = response.resdata?.listPayment else {
                    return
                }
                
                guard let responseData = validResponse.data(using: .utf8) else {
                    print("Problem in response data parsing...")
                    return
                }
                
                guard let payHistList = try? JSONDecoder().decode([PayHist].self, from: responseData) else {
                    return
                }
                
                if payHistList.count > 0 {
                    self.payHistList.append(contentsOf: payHistList)
                    self.objectWillChange.send(true)
                }
            })
    }
    
    func executePayHistApiCall(value: String, SDate: String, EDate: String) -> AnyPublisher<PayHistResponse, Error>? {
        payHistPageNumber += 1
        let jsonObject = ["UserID": UserLocalStorage.getLoggedUserData()?.userID ?? 0, "pageNumber": payHistPageNumber, "pageSize": 30, "values": value , "SDate": SDate, "EDate": EDate] as [String : Any]
        let jsonArray = [jsonObject]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
  
        guard let params = String(data: jsonData, encoding: String.Encoding.ascii) else {
            print("Problem in parameter creation...")
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/billhistory") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
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
        .decode(type: PayHistResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - getUserBalance()
    // Gets user's current account balance, dues etc.
    func getUserBalance() {
        self.userBalanceSubscriber = self.executeUserBalanceApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                if let userBalance = response.resdata?.billIspUserBalance {
                    self.userBalance = userBalance
                }
            })
    }
    
    func executeUserBalanceApiCall() -> AnyPublisher<UserBalanceResponse, Error>? {
        let jsonObject = ["UserID": UserLocalStorage.getLoggedUserData()?.userID ?? 0]
        let jsonArray = [jsonObject]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
       
        guard let params = String(data: jsonData, encoding: String.Encoding.ascii) else {
            print("Problem in parameter creation...")
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/billispuserbalance") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
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
        .decode(type: UserBalanceResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    // MARK: - getUserPackServiceData()
    // Gets user's current all active and inactive services
    func getUserPackServiceData() {
        self.userPackServiceSubscriber = self.executeUserPackServiceApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                if response.count > 0 {
                    guard let packServices = response[0].packList else {
                        return
                    }
                    self.userPackServices = packServices
                }
                
            })
    }
    
    func executeUserPackServiceApiCall() -> AnyPublisher<[UserPackServiceList], Error>? {
        let userId = UserLocalStorage.getLoggedUserData()?.userID
        let jsonObject = ["id": userId]
        let jsonArray = [jsonObject]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            print("Problem in parameter creation...")
            return nil
        }
 
        guard let params = String(data: jsonData, encoding: String.Encoding.ascii) else {
            print("Problem in parameter creation...")
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispuser/getprofileuserbyid") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
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
                
                let jsonString = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                print(jsonString ?? "Error in json parsing...")
                let tempString = jsonString?["resdata"] as? [String: String]
                let tempAgain = tempString?["listProfileUser"]
                guard let finalData = tempAgain?.data(using: .utf8) else {
                    print("Problem in response data parsing...")
                    return data
                }
                
                return finalData
        }
        .retry(1)
        .decode(type: [UserPackServiceList].self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func refreshUI() {
        showLoader.send(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.invoicePageNumber = -1
            self.payHistPageNumber = -1
            self.invoiceList.removeAll()
            self.payHistList.removeAll()
            self.getUserInvoiceList()
            self.getUserPayHistory(value: "", SDate: "", EDate: "")
        }
    }
    
    func refreshInvoice() {
        showLoader.send(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.invoicePageNumber = -1
            self.invoiceList.removeAll()
            self.getUserInvoiceList()
        }
    }
    
    func refreshPayment() {
        showLoader.send(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.payHistPageNumber = -1
            self.payHistList.removeAll()
            self.getUserPayHistory(value: "", SDate: "", EDate: "")
        }
    }
}
