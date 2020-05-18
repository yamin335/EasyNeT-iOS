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
    static let webBaseUrl = "https://api.pacenet.net"
    enum APIFailureCondition: Error {
        case InvalidServerResponse
    }
}

func getCommonUrlRequest(url: URL) -> URLRequest {
    //Request type
    var request = URLRequest(url: url)
    //Setting common headers
    let loggedUser = UserLocalStorage.getUserCredentials().loggedUser
    request.setValue(loggedUser?.ispToken ?? "", forHTTPHeaderField: "AuthorizedToken")
    let userId = loggedUser?.userID ?? 0
    request.setValue(String(userId), forHTTPHeaderField: "userId")
    request.setValue("3", forHTTPHeaderField: "platformId")
    
    return request
}
