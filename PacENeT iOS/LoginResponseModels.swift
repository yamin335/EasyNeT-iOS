//
//  LoginResponseModels.swift
//  Pace Cloud
//
//  Created by rgl on 6/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import Foundation

// MARK: - LoginResponse
struct LoginResponse: Codable {
    var resdata: LoginResdata
}

// MARK: - LoginResdata
struct LoginResdata: Codable {
    var loggeduser: Loggeduser?
    var message: String?
}

// MARK: - Loggeduser
struct Loggeduser: Codable {
    var userID: Int?
    var userName: String?
    var email: String?
}
