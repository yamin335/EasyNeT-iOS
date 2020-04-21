//
//  DashboardViewModel.swift
//  PacENeT iOS
//
//  Created by Yamin on 19/3/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    private var sessionChartSubscriber: AnyCancellable? = nil
    var showLoader = PassthroughSubject<Bool, Never>()
    var sessionChartDataPublisher = PassthroughSubject<Bool, Never>()
    var sessionChartData: [SessionChartData]? = nil
    var typeIndexPublisher = PassthroughSubject<Int, Never>()
    var monthIndexPublisher = PassthroughSubject<Int, Never>()
    var tempTypeindex = 0
    var tempMonthIndex = 0
    
    //@Published var pieChartTitle = ""
    
    deinit {
        sessionChartSubscriber?.cancel()
    }
    
    func restoreModalState() {
        typeIndexPublisher.send(tempTypeindex)
        monthIndexPublisher.send(tempMonthIndex)
    }
    
    func getSessionChartData(month: Int, type: String) {
        self.sessionChartSubscriber = self.executeSessionChartApiCall(month: month, type: type)?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }, receiveValue: { response in
                self.sessionChartData = response.resdata.sessionChartData
                if self.sessionChartData?.count ?? 0 > 0 {
                    self.sessionChartDataPublisher.send(true)
                } else {
                    self.sessionChartDataPublisher.send(false)
                }
            })
    }
    
    func executeSessionChartApiCall(month: Int, type: String) -> AnyPublisher<DashSessionResponse, Error>? {
        let userCredentials = UserLocalStorage.getUserCredentials()
        let jsonObject = ["CompanyId": 1,
                          "userName": userCredentials.userName,
                          "values": type,
                          "month": month] as [String : Any]
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
        guard var urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/getbizispsessionchart") else {
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
                
                let string = String(data: data, encoding: .utf8)
                print(string ?? "Undefined session data")
                return data
        }
        .retry(1)
        .decode(type: DashSessionResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
}
