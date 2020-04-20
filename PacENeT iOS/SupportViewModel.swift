//
//  SupportViewModel.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 3/31/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import Combine

class SupportViewModel: ObservableObject {
    
    private var supportTicketListSubscriber: AnyCancellable? = nil
    private var ticketDetailListSubscriber: AnyCancellable? = nil
    private var sendMessageSubscriber: AnyCancellable? = nil
    private var ticketCategorySubscriber: AnyCancellable? = nil
    private var newTicketEntrySubscriber: AnyCancellable? = nil
    var newEntryPublisher = PassthroughSubject<Bool, Never>()
    var objectWillChange = PassthroughSubject<Bool, Never>()
    var showLoader = PassthroughSubject<Bool, Never>()
    var pageNumber = -1
    var choosenImage: ImageData?
    
    @Published var choosenImageList = [ImageData]() {
        didSet {
            self.objectWillChange.send(true)
        }
    }
    
    @Published var ticketCategoryList = [TicketCategory]()
    
    @Published var supportTicketList = [SupportTicket]()
    
    @Published var ticketDetailList = [ISPTicketConversation]() {
        didSet {
            self.objectWillChange.send(true)
        }
    }
    
    init() {
        getTicketCategory()
    }
    
    deinit {
        self.supportTicketListSubscriber?.cancel()
        self.ticketDetailListSubscriber?.cancel()
        self.sendMessageSubscriber?.cancel()
        self.ticketCategorySubscriber?.cancel()
        self.newTicketEntrySubscriber?.cancel()
    }
    
    func getSupportTicketList() {
        self.supportTicketListSubscriber = self.executeSupportTicketListApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        //self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                    //                        fatalError(error.localizedDescription)
                }
            }, receiveValue: { response in
                guard let supportticketlist = response.resdata?.listCrmIspTicket else {
                    return
                }
                self.supportTicketList.append(contentsOf: supportticketlist)
                self.objectWillChange.send(true)
            })
    }
    
    func executeSupportTicketListApiCall() -> AnyPublisher<SupportTicketResponse, Error>? {
        pageNumber += 1
        let jsonObject = ["ispUserId": UserLocalStorage.getLoggedUserData()?.userID ?? 0, "pageNumber": pageNumber, "pageSize": 30]
        
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
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/getbypageispticket") else {
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
        .decode(type: SupportTicketResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func getTicketDetail(ispTicketId: Int) {
        self.ticketDetailListSubscriber = self.executeTicketDetailApiCall(ispTicketId: ispTicketId)?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        //self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                    //                        fatalError(error.localizedDescription)
                }
            }, receiveValue: { response in
                guard let ticketConversation = response.resdata?.objCrmIspTicket?.listIspTicketConversation else {
                    return
                }
                self.ticketDetailList = ticketConversation.reversed()
            })
    }
    
    func executeTicketDetailApiCall(ispTicketId: Int) -> AnyPublisher<SupportTicketDetailResponse, Error>? {
        let jsonObject = ["id" : ispTicketId]
        
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
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/getbyidispticket") else {
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
        .decode(type: SupportTicketDetailResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func sendNewMessage(newMessage: String, ispTicketId: Int) {
        self.sendMessageSubscriber = self.executeSendMessageApiCall(newMessage: newMessage, ispTicketId: ispTicketId)?
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
                        self.getTicketDetail(ispTicketId: ispTicketId)
                        self.choosenImage = nil
                    }
                }
            })
    }
    
    func executeSendMessageApiCall(newMessage: String, ispTicketId: Int) -> AnyPublisher<DefaultResponse, Error>? {
        
        let formFields = ["ispTicketId": String(ispTicketId), "ispUserId": String(UserLocalStorage.getLoggedUserData()?.userID ?? 0), "ticketComment": newMessage]

        let boundary = "Boundary-\(UUID().uuidString)"
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/saveispticketconversation") else {
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
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let httpBody = NSMutableData()

        for (key, value) in formFields {
          httpBody.appendString(convertFormField(named: key, value: value, using: boundary))
        }
        
        if let imageData = choosenImage {
            httpBody.append(convertFileData(fieldName: "attachedFileComment",
                                            fileName: imageData.name,
                                            mimeType: "image/jpeg",
                                            fileData: imageData.data,
                                            using: boundary))
        }

        httpBody.appendString("--\(boundary)--")

        //Setting body for POST request
        request.httpBody = httpBody as Data
        
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
    
    func saveNewTicket(ticketSummary: String, ticketDescription: String, ispTicketCategoryId: Int) {
        self.newTicketEntrySubscriber = self.executeSaveTicketApiCall(ticketSummary: ticketSummary, ticketDescription: ticketDescription, ispTicketCategoryId: ispTicketCategoryId)?
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
                        self.newEntryPublisher.send(true)
                        self.choosenImageList.removeAll()
                    }
                }
            })
    }
    
    func executeSaveTicketApiCall(ticketSummary: String, ticketDescription: String, ispTicketCategoryId: Int) -> AnyPublisher<DefaultResponse, Error>? {
        
        let formFields = ["ticketSummary": ticketSummary, "ticketDescription": ticketDescription, "ispTicketCategoryId": String(ispTicketCategoryId), "ispUserId": String(UserLocalStorage.getLoggedUserData()?.userID ?? 0)]

        let boundary = "Boundary-\(UUID().uuidString)"
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/saveupdateispticket") else {
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
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let httpBody = NSMutableData()

        for (key, value) in formFields {
          httpBody.appendString(convertFormField(named: key, value: value, using: boundary))
        }
        
        for file in choosenImageList {
            httpBody.append(convertFileData(fieldName: "attachedFileComment",
                                            fileName: file.name,
                                            mimeType: "image/jpeg",
                                            fileData: file.data,
                                            using: boundary))
        }

        httpBody.appendString("--\(boundary)--")

        //Setting body for POST request
        request.httpBody = httpBody as Data
        
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
    
    func getTicketCategory() {
        self.supportTicketListSubscriber = self.executeTicketCategoryApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        //self.errorToastPublisher.send((true, error.localizedDescription))
                        print(error.localizedDescription)
                    //                        fatalError(error.localizedDescription)
                }
            }, receiveValue: { response in
                guard let ticketCategoryList = response.resdata?.listTicketCategory else {
                    return
                }
                self.ticketCategoryList = ticketCategoryList
            })
    }
    
    func executeTicketCategoryApiCall() -> AnyPublisher<TicketCategoryResponse, Error>? {
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
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/dropdown/getispticketcategory") else {
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
        .decode(type: TicketCategoryResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
    func convertFormField(named name: String, value: String, using boundary: String) -> String {
      var fieldString = "--\(boundary)\r\n"
      fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
      fieldString += "\r\n"
      fieldString += "\(value)\r\n"

      return fieldString
    }

    func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
      let data = NSMutableData()
      data.appendString("--\(boundary)\r\n")
      data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
      data.appendString("Content-Type: \(mimeType)\r\n\r\n")
      data.append(fileData)
      data.appendString("\r\n")

      return data as Data
    }
}

extension NSMutableData {
  func appendString(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}

