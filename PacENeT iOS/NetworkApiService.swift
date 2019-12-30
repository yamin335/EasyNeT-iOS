//
//  NetworkApiService.swift
//  Pace Cloud
//
//  Created by rgl on 3/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import Foundation
import Combine
class NetworkApiService {
    static let webBaseUrl = "http://123.136.26.98:8081"
    enum APIFailureCondition: Error {
        case InvalidServerResponse
    }
}

func getCommonUrlRequest(url: URL) -> URLRequest {
    //Request type
    var request = URLRequest(url: url)
    
    //Setting common headers
    request.setValue("cmdsX3NlY3JldF9hcGlfa2V5", forHTTPHeaderField: "AuthorizedToken")
    
    return request
}
