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
    var showLoader = PassthroughSubject<Bool, Never>()
    var objectHasChanged = PassthroughSubject<Bool, Never>()
    var showServiceChangeModal = PassthroughSubject<(Bool, UserPackService), Never>()
    var packServices = [PackService]()
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
    
    // MARK: - deinit()
    deinit {
        packServiceSubscriber?.cancel()
        userPackServiceSubscriber?.cancel()
        userPackServiceChangeSaveSubscriber?.cancel()
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
                        //self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                if let resstate = response.resdata.resstate {
                    if resstate == true {
                        self.getUserPackServiceData()
                    }
                }
            })
    }
    
    func executeSavePackServiceApiCall(selectedPackService: ChildPackService, changingUserPackService: UserPackService) -> AnyPublisher<DefaultResponse, Error>? {
        
        let newPackService: NewPackService = NewPackService(userPackServiceId: changingUserPackService.userPackServiceId, connectionNo: changingUserPackService.connectionNo, userId: changingUserPackService.userId, connectionTypeId: changingUserPackService.connectionTypeId, zoneId: changingUserPackService.zoneId, accountId: changingUserPackService.accountId, packServiceId: selectedPackService.packServiceId, packServiceName: selectedPackService.packServiceName, parentPackServiceId: selectedPackService.parentPackServiceId, parentPackServiceName: selectedPackService.parentPackServiceName, packServiceTypeId: selectedPackService.packServiceTypeId, packServiceType: selectedPackService.packServiceType, packServicePrice: selectedPackService.packServicePrice, packServiceInstallCharge: changingUserPackService.packServiceInstallCharge, packServiceOthersCharge: changingUserPackService.packServiceOthersCharge, payAmount: changingUserPackService.payAmount, saveAmount: changingUserPackService.saveAmount, methodId: changingUserPackService.methodId, isUpGrade: changingUserPackService.isUpGrade, isDownGrade: changingUserPackService.isDownGrade, isDefault: changingUserPackService.isDefault, expireDate: changingUserPackService.expireDate, activeDate: changingUserPackService.activeDate, isNew: changingUserPackService.isNew, isUpdate: true, isDelete: false, enabled: changingUserPackService.enabled, deductBalance: 0.0, isBalanceDeduct: true, isActive: changingUserPackService.isActive)
        
        let packUserInfo: PackUserInfo = PackUserInfo(id: changingUserPackService.accountId, userId: changingUserPackService.userId, values: "\(changingUserPackService.packServiceName ?? ""), \(selectedPackService.packServiceName ?? "")", loggeduserId: UserLocalStorage.getLoggedUserData()?.userID)
        
        let newPackageSaveList = [NewPackageSave.newPackServiceArray([newPackService]), NewPackageSave.packUserInfo(packUserInfo)]
        
        let jsonData = try? JSONEncoder().encode(newPackageSaveList)
        
        var jsonString: Any?
        if let data = jsonData { jsonString = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) }
        print(jsonString ?? "Error in json parsing...")
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispuser/saveupdateuserpackserivce") else {
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
    
    func refreshUI() {
        getUserPackServiceData()
        getPackServiceData()
    }
}
