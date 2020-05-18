//
//  MainScreenViewModel.swift
//  PacENeT iOS
//
//  Created by Yamin on 19/3/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import Combine

class MainScreenViewModel: ObservableObject {
    private var userDataSubscriber: AnyCancellable? = nil
    var showLoader = PassthroughSubject<Bool, Never>()
    
    deinit {
        userDataSubscriber?.cancel()
    }
    
    func getUserData() {
        self.userDataSubscriber = self.executeUserDataApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                    print(error.localizedDescription)
                }
            }, receiveValue: { response in
                if response.count > 0 {
                    UserLocalStorage.saveLoggedUserData(loggedUserData: response[0])
                }
            })
    }
    
    func executeUserDataApiCall() -> AnyPublisher<[LoggedUserData], Error>? {
        let user = UserLocalStorage.getUserCredentials()
        let jsonObject = ["userName": user.userName] as [String : Any]
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
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/getuserisp") else {
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
                print(jsonString ?? "not right")
                let tempString = jsonString?["resdata"] as? [String: String]
                let tempAgain = tempString?["userIsp"]
                guard let finalData = tempAgain?.data(using: .utf8) else {
                    print("Problem in response data parsing...")
                    return data
                }
                
                return finalData
        }
        .retry(1)
        .decode(type: [LoggedUserData].self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
}
