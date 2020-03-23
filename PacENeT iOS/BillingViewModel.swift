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

    @Published var rechargeAmount: String = ""
    @Published var rechargeNote: String = ""
    var paymentRequest: PaymentRequest? = nil
    @Published var invalidAmountMessage: String {
        willSet {
            objectWillChange.send(true)
        }
    }
    
    var objectWillChange = PassthroughSubject<Bool, Never>()
    
    private var postAmountSubscriber: AnyCancellable? = nil
    private var validAmountChecker: AnyCancellable? = nil
    private var fosterStatusSubscriber: AnyCancellable? = nil
    private var fosterRechargeSaveSubscriber: AnyCancellable? = nil
    private var getBkashTokenSubscriber: AnyCancellable? = nil
    private var createBkashPaymentSubscriber: AnyCancellable? = nil
    private var executeBkashPaymentSubscriber: AnyCancellable? = nil
    private var finishBkashPaymentSubscriber: AnyCancellable? = nil
    
    var showLoader = PassthroughSubject<Bool, Never>()
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var okButtonDisablePublisher = PassthroughSubject<Bool, Never>()
    var fosterWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var bkashWebViewNavigationPublisher = PassthroughSubject<String, Never>()
    var showFosterWebViewPublisher = PassthroughSubject<Bool, Never>()
    var showBkashWebViewPublisher = PassthroughSubject<Bool, Never>()
    var bkashCreatePaymentPublisher = PassthroughSubject<String, Never>()
    var bkashPaymentStatusPublisher = PassthroughSubject<(Bool, String?), Never>()
    
    var fosterStatusUrl = ""
    var fosterProcessUrl = ""
    var bkashToken = ""
    var bkashPaymentExecuteJson: [String: Any] = [:]
    
    var bkashTokenModel: TModel? = nil
    private var validDigits = CharacterSet(charactersIn: "1234567890.")
    
    init() {
        invalidAmountMessage = ""
        validAmountChecker = $rechargeAmount.sink { val in
            //check if the new string contains any invalid characters
            if val.rangeOfCharacter(from: self.validDigits.inverted) != nil {
                //clean the string (do this on the main thread to avoid overlapping with the current ContentView update cycle)
                DispatchQueue.main.async {
                    self.rechargeAmount = String(self.rechargeAmount.unicodeScalars.filter {
                        self.validDigits.contains($0)
                    })
                }
            }
            
            let amount = Double(val) ?? 0.0
            if amount > 0.0 {
                self.okButtonDisablePublisher.send(false)
                DispatchQueue.main.async {
                    self.invalidAmountMessage = ""
                }
            } else {
                self.okButtonDisablePublisher.send(true)
                DispatchQueue.main.async {
                    self.invalidAmountMessage = "Invalid Amount"
                }
            }
        }
    }
    
    deinit {
        postAmountSubscriber?.cancel()
        validAmountChecker?.cancel()
        fosterStatusSubscriber?.cancel()
        fosterRechargeSaveSubscriber?.cancel()
        getBkashTokenSubscriber?.cancel()
        createBkashPaymentSubscriber?.cancel()
        executeBkashPaymentSubscriber?.cancel()
        finishBkashPaymentSubscriber?.cancel()
    }
    
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
                if response.resdata?.tModel != nil {
                    self.bkashTokenModel = response.resdata?.tModel
                    self.showBkashWebViewPublisher.send(true)
                } else {
                    self.errorToastPublisher.send((true, "Did not get token, please try again!"))
                }
            })
    }
    
    func executeGetBkashTokenApiCall() -> AnyPublisher<BKashTokenResponse, Error>? {
        let jsonObject = ["id": 0]
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
        let tempParams = String(data: jsonData, encoding: String.Encoding.ascii)
        guard let params = tempParams else {
            print("Problem in parameter creation...")
            return nil
        }
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/portal/generatebkashtoken") else {
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
                if !(response.resdata?.resbKash?.isEmpty)! && response.resdata?.resbKash != nil {
                    self.bkashCreatePaymentPublisher.send((response.resdata?.resbKash)!)
                } else {
                    self.errorToastPublisher.send((true, "Can not create payment, please try again!"))
                }
            })
    }
    
    func createBkashPaymentApiCall() -> AnyPublisher<BKashCreatePaymentResponse, Error>? {
        
        guard let data = bkashTokenModel?.token?.data(using: .utf8) else {
            print("Problem in response data parsing...")
            return nil
        }
        
        let tokenJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        
        bkashToken = tokenJson?["id_token"] as! String
        
        let jsonObject = ["authToken": tokenJson?["id_token"] as? String,
                          "rechargeAmount": rechargeAmount,
                          "Name": "sale",
                          "currency": bkashTokenModel?.currency,
                          "mrcntNumber": bkashTokenModel?.marchantInvNo] as [String : Any?]
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
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/portal/createbkashpayment") else {
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
                if !(response.resdata?.resExecuteBk?.isEmpty)! && response.resdata?.resExecuteBk != nil {
                    self.saveBkashPayment(bkashPaymentResponse: (response.resdata?.resExecuteBk)!)
                } else {
                    self.errorToastPublisher.send((true, "Can not execute payment, please try again!"))
                }
            })
    }
    
    func executeBkashPaymentApiCall() -> AnyPublisher<BKashExecutePaymentResponse, Error>? {
        
        let jsonObject = ["authToken": bkashToken,
                          "paymentID": bkashPaymentExecuteJson["paymentID"] as? String] as [String : Any?]
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
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/portal/executebkashpayment") else {
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
                self.bkashPaymentStatusPublisher.send((response.resdata.resstate!, response.resdata.message))
            })
    }
    
    func saveBkashPaymentApiCall(bkashPaymentModel: String) -> AnyPublisher<DefaultResponse, Error>? {
        let bkashData = Data(bkashPaymentModel.utf8)
        let bkashJson = try? JSONSerialization.jsonObject(with: bkashData, options: .allowFragments) as? [String: Any]

        let user = UserLocalStorage.getLoggedUserData()
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let today = format.string(from: date)
        let jsonObject = ["CloudUserID": user?.userID ?? 0,
                          "UserTypeId": user?.userType ?? 0,
                          "TransactionNo": bkashJson?["trxID"] as Any,
                          "InvoiceId": 0,
                          "UserName": user.displayName as Any,
                          "TransactionDate": today,
                          "RechargeType": "bkash",
                          "BalanceAmount": bkashJson?["amount"] as Any,
                          "Particulars": "",
                          "IsActive": true] as [String : Any]
        
        let jsonArray = [jsonObject, bkashJson]
        if !JSONSerialization.isValidJSONObject(jsonArray) {
            print("Problem in parameter creation...")
            return nil
        }
        
        let tempJson = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
        
        guard let jsonData = tempJson else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/portal/newrechargebkashpayment") else {
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
    
    func getFosterPaymentUrl() {
        self.postAmountSubscriber = self.executeGetFosterUrlApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                    //                        fatalError(error.localizedDescription)
                }
            }, receiveValue: { response in
                if let resstate = response.resdata.resstate {
                    if resstate == true {
                        self.showFosterWebViewPublisher.send(true)
                        self.fosterStatusUrl = response.resdata.paymentStatusUrl ?? ""
                        self.fosterProcessUrl = response.resdata.paymentProcessUrl ?? ""
                        print(self.fosterStatusUrl)
                    } else {
                        self.errorToastPublisher.send((true, response.resdata.message ?? "Please try some times later!"))
                    }
                }
            })
    }
    
    func executeGetFosterUrlApiCall() -> AnyPublisher<PostAmountResponse, Error>? {
        let user = UserLocalStorage.getUser()
        let jsonObject = ["UserID": user.userID ?? 0, "rechargeAmount": rechargeAmount] as [String : Any]
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
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/billclouduserclient/cloudrecharge") else {
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
        .decode(type: PostAmountResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
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
                if let resstate = response.resdata.resstate {
                    if resstate == true {
                        self.saveFosterRecharge(fosterModel: response.resdata.fosterRes ?? "")
                    } else {
                        self.errorToastPublisher.send((true, "Recharge not successful !"))
                    }
                }
            })
    }
    
    func executeFosterStatusApiCall() -> AnyPublisher<FosterStatusCheckModel, Error>? {
        let jsonObject = ["statusCheckUrl": fosterStatusUrl]
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
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/billclouduserclient/cloudrechargesave") else {
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
        .decode(type: FosterStatusCheckModel.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
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
                if let resstate = response.resdata.resstate {
                    if resstate == true {
                        self.successToastPublisher.send((true, response.resdata.message ?? "Recharge successful"))
                        self.refreshUI()
                    } else {
                        self.errorToastPublisher.send((true, response.resdata.message ?? "Recharge not successful"))
                    }
                }
            })
    }
    
    func executeFosterRechargeSaveApiCall(fosterModel: String) -> AnyPublisher<DefaultResponse, Error>? {
        
        let fosterData = Data(fosterModel.utf8)
        let fosterResponseModelArray = try? JSONDecoder().decode([FosterModel].self, from: fosterData)
        let fosterResponseModel = fosterResponseModelArray?[0]
        let user = UserLocalStorage.getUser()
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let today = format.string(from: date)
        let jsonObject = ["CloudUserID": user.userID ?? 0,
                          "UserTypeId": user.userType ?? 0,
                          "TransactionNo": fosterResponseModel?.MerchantTxnNo,
                          "InvoiceId": 0,
                          "UserName": user.displayName,
                          "TransactionDate": today,
                          "RechargeType": "foster",
                          "BalanceAmount": fosterResponseModel?.TxnAmount,
                          "Particulars": "",
                          "IsActive": true] as [String : Any?]
        let fosterJsonData = try! JSONEncoder().encode(fosterResponseModel)
        let fosterJsonObject = try? JSONSerialization.jsonObject(with: fosterJsonData, options: .allowFragments) as? [String: Any?]
        
        let jsonArray = [jsonObject, fosterJsonObject]
        if !JSONSerialization.isValidJSONObject(jsonArray) {
            print("Problem in parameter creation...")
            return nil
        }
        
        let tempJson = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
        
        guard let jsonData = tempJson else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl + "/api/portal/newrechargesave") else {
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
