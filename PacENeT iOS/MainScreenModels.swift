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
    let userCode: String?
    let userPass: String?
    let ownerId: String?
    let profile: String?
    let enabled: Bool?
    let expiration: String?
    let createdBy: String?
    let createDate: String?
    let lastIp: String?
    let lastLogin: String?
    let billingPlan: Bool?
    let userTypeId: Int?
    let userType: String?
}
