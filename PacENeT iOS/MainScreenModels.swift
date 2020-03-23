//
//  MainScreenModels.swift
//  PacENeT iOS
//
//  Created by Yamin on 19/3/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation

// MARK: - UserDataResponse
struct UserDataResponse: Codable {
    let resdata: UserDataResdata
}

// MARK: - UserDataResdata
struct UserDataResdata: Codable {
    let userIsp: String?
}

// MARK: - LoggedUserData
struct LoggedUserData: Codable {
    let userID: Int?
    let userName: String?
    let fullName: String?
    let displayName: String?
    let emailAddr: String?
    let email: String?
    let phone: String?
    let balance: Double?
    let profileID: Int?
    let srvName: String?
    let unitPrice: Double?
    let created: String?
    let companyName: String?
    let Address: String?
}
