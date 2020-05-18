//
//  ProfileViewModel.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 3/31/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    
    // MARK: - Properties
    private var packServiceSubscriber: AnyCancellable? = nil
    private var userPackServiceSubscriber: AnyCancellable? = nil
    private var userPackServiceChangeSaveSubscriber: AnyCancellable? = nil
    private var userBalanceSubscriber: AnyCancellable? = nil
    private var packChangePayConsumeSubscriber: AnyCancellable? = nil
    
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var warningToastPublisher = PassthroughSubject<(Bool, String), Never>()
    
    var showLoader = PassthroughSubject<Bool, Never>()
    var objectHasChanged = PassthroughSubject<Bool, Never>()
    var showServiceChangeModal = PassthroughSubject<(Bool, UserPackService), Never>()
    var packServices = [PackService]()
    var showPackageChangePayModalPublisher = PassthroughSubject<([PayMethod], PackageChangeConsumeData), Never>()
    var packChangeHelper: PackageChangeHelper? = nil
    var payMethods: [PayMethod] = []
    var consumeData: PackageChangeConsumeData? = nil
    
    @Published var balance = ""
    @Published var due = ""
    
    
    @Published var userBalance: UserBalance? {
        willSet {
            self.balance = "\(newValue?.balanceAmount?.rounded(toPlaces: 2) ?? "0.0") BDT"
            self.due = "\(newValue?.duesAmount?.rounded(toPlaces: 2) ?? "0.0") BDT"
            objectHasChanged.send(true)
        }
    }
    
    @Published var userPackServices = [UserPackService]() {
        didSet {
            objectHasChanged.send(true)
        }
    }
    private var existedServices = [Int]()
    @Published var choosingPackServiceOptions = [ChildPackService]() {
        didSet {
            objectHasChanged.send(true)
        }
    }
    private var tempChoosingOptions = [ChildPackService]()
    
    //MARK: - init()
//    init() {
//        getUserBalance()
//    }
    
    // MARK: - deinit()
    deinit {
        packServiceSubscriber?.cancel()
        userPackServiceSubscriber?.cancel()
        userPackServiceChangeSaveSubscriber?.cancel()
        userBalanceSubscriber?.cancel()
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
    
    // MARK: - refactorPackageChangeSheetData()
    func refactorPackageChangeSheetData(selectedPackService: ChildPackService) {
        
        var choosingOptions = [ChildPackService]()
        
        for service in tempChoosingOptions {
            guard let id = service.packServiceId else {
                continue
            }
            if !existedServices.contains(id) && id != selectedPackService.packServiceId {
                choosingOptions.append(service)
            }
        }
        
        choosingPackServiceOptions = choosingOptions
    }
    
    // MARK: - preparePackageChangeSheetData()
    func preparePackageChangeSheetData(changingUserPackService: UserPackService) {
        existedServices.removeAll()
        for service in userPackServices {
            existedServices.append(service.packServiceId ?? 0)
        }
        
        for service in packServices {
            if service.packServiceId == changingUserPackService.parentPackServiceId {
                tempChoosingOptions = service.childPackServices ?? [ChildPackService]()
            }
        }
        
        var choosingOptions = [ChildPackService]()
        
        for service in tempChoosingOptions {
            guard let id = service.packServiceId else {
                continue
            }
            if !existedServices.contains(id) && id != changingUserPackService.packServiceId {
                choosingOptions.append(service)
            }
        }
        
        choosingPackServiceOptions = choosingOptions
    }
    
    // MARK: - getUserPackServiceData()
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

    // MARK: - saveChangedPackService()
    func saveChangedPackService(selectedPackService: ChildPackService, changingUserPackService: UserPackService) {
        self.userPackServiceChangeSaveSubscriber = self.executeSavePackServiceApiCall(selectedPackService: selectedPackService, changingUserPackService: changingUserPackService)?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                        self.errorToastPublisher.send((true, "Not successful, contact with support! -- \(error.localizedDescription)"))
                }
            }, receiveValue: { response in
                if let resdata = response.resdata {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.getUserPackServiceData()
                    }
                    self.successToastPublisher.send((true, resdata.message ?? "Successfully changed!"))
                    self.showLoader.send(true)
                } else {
                    self.errorToastPublisher.send((true, "Not successful, contact with support!"))
                }
            })
    }
    
    func executeSavePackServiceApiCall(selectedPackService: ChildPackService, changingUserPackService: UserPackService) -> AnyPublisher<DefaultResponse, Error>? {
        
        guard let helper = packChangeHelper else {
            errorToastPublisher.send((true, "Not possible at this moment, please try again later!!"))
            return nil
        }
        
        let newPackService: NewPackService = NewPackService(userPackServiceId: changingUserPackService.userPackServiceId,
                                                            connectionNo: changingUserPackService.connectionNo,
                                                            userId: changingUserPackService.userId,
                                                            connectionTypeId: changingUserPackService.connectionTypeId,
                                                            zoneId: changingUserPackService.zoneId,
                                                            accountId: changingUserPackService.accountId,
                                                            packServiceId: selectedPackService.packServiceId,
                                                            packServiceName: selectedPackService.packServiceName,
                                                            parentPackServiceId: selectedPackService.parentPackServiceId,
                                                            parentPackServiceName: selectedPackService.parentPackServiceName,
                                                            packServiceTypeId: selectedPackService.packServiceTypeId,
                                                            packServiceType: selectedPackService.packServiceType,
                                                            packServicePrice: selectedPackService.packServicePrice,
                                                            packServiceInstallCharge: changingUserPackService.packServiceInstallCharge,
                                                            packServiceOthersCharge: changingUserPackService.packServiceOthersCharge,
                                                            actualPayAmount: helper.requiredAmount,
                                                            payAmount: helper.requiredAmount,
                                                            saveAmount: helper.savedAmount,
                                                            methodId: changingUserPackService.methodId,
                                                            isUpGrade: helper.isUpgrade,
                                                            isDownGrade: !helper.isUpgrade,
                                                            isDefault: changingUserPackService.isDefault,
                                                            expireDate: changingUserPackService.expireDate,
                                                            activeDate: changingUserPackService.activeDate,
                                                            isNew: false,
                                                            isUpdate: true,
                                                            isDelete: false,
                                                            enabled: changingUserPackService.enabled,
                                                            deductBalance: helper.deductedAmount, isBalanceDeduct: helper.deductedAmount > 0.0 ? true : false,
                                                            isActive: changingUserPackService.isActive)
        
        let packUserInfo: PackUserInfo = PackUserInfo(id: changingUserPackService.accountId, userId: changingUserPackService.userId, values: "\(changingUserPackService.packServiceName ?? ""), \(selectedPackService.packServiceName ?? "")", loggeduserId: UserLocalStorage.getLoggedUserData()?.userID)
        
        let newPackageSaveList = [NewPackageSave.newPackServiceArray(newPackService), NewPackageSave.packUserInfo(packUserInfo)]
        
        let jsonData = try? JSONEncoder().encode(newPackageSaveList)
        
        var jsonString: Any?
        if let data = jsonData { jsonString = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) }
        print(jsonString ?? "Error in json parsing...")
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispuser/saveupdatesingleuserpackserivce") else {
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
                
                let string = String(data: data, encoding: .utf8)
                print(string ?? "Undefined session data")
                
                return data
        }
        .retry(1)
        .decode(type: DefaultResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }

    // MARK: - getPackServiceData()
    func getPackServiceData() {
        self.packServiceSubscriber = self.executePackServiceApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                if response.count > 0 {
                    self.packServices = response
                }
            })
    }
    
    func executePackServiceApiCall() -> AnyPublisher<[PackService], Error>? {
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
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispuser/getbizisppackservice") else {
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
                let tempAgain = tempString?["ispservices"]
                guard let finalData = tempAgain?.data(using: .utf8) else {
                    print("Problem in response data parsing...")
                    return data
                }
                
                return finalData
        }
        .retry(1)
        .decode(type: [PackService].self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func getPackChangeConsumeData(userPackServiceId: Int) -> AnyPublisher<PackageChangeConsumeResponse, Error> {
        let jsonObject = ["userPackServiceId": userPackServiceId]
        let jsonArray = [jsonObject]
        let jsonData = try! JSONSerialization.data(withJSONObject: jsonArray, options: [])
        let params = String(data: jsonData, encoding: String.Encoding.ascii)
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/getuserpackserviceconsumdata")
        urlComponents?.queryItems = queryItems
        
        let url = urlComponents?.url
        
        var request = getCommonUrlRequest(url: url!)
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
        .decode(type: PackageChangeConsumeResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func getPayMethods() -> AnyPublisher<PayMethodResponse, Error> {
        let jsonObject: [String: Any?] = [:]
        let jsonArray = [jsonObject]

        let jsonData = try! JSONSerialization.data(withJSONObject: jsonArray, options: [])
        let params = String(data: jsonData, encoding: String.Encoding.ascii)
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "param", value: params))
        var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/dropdown/getisppaymentmethod")
        urlComponents?.queryItems = queryItems
        
        let url = urlComponents?.url
        
        var request = getCommonUrlRequest(url: url!)
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
        .decode(type: PayMethodResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func getPayMethodsAndConsumeData(selectedPackServiceId: Int) {
        self.packChangePayConsumeSubscriber = Publishers.Zip(getPayMethods(), getPackChangeConsumeData(userPackServiceId: selectedPackServiceId))
            .receive(on: RunLoop.main) // <<—— run on main thread
            .eraseToAnyPublisher()
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }, receiveValue: { (payMethodResponse, consumeDataResponse) in
                guard let payMethods = payMethodResponse.resdata?.listPaymentMethod, let consumeData = consumeDataResponse.resdata else {
                    return
                }
                self.showPackageChangePayModalPublisher.send((payMethods, consumeData))
            })
    }
    
    func refreshUI() {
        getUserPackServiceData()
        getPackServiceData()
    }
}
