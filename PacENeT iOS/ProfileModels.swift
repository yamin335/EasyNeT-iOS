//
//  ProfileModels.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 3/31/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation

// MARK: - UserPackServiceResponse
struct UserPackServiceResponse: Codable {
    let resdata: UserPackServiceResdata?
}

// MARK: - UserPackServiceResdata
struct UserPackServiceResdata: Codable {
    let listProfileUser: String?
}

// MARK: - UserPackServiceList
struct UserPackServiceList: Codable {
    let userConnectionId, ispUserId: Int?
    let ContactPerson, packServices: String?
    let packList: [UserPackService]?
}

// MARK: - UserPackService
struct UserPackService: Codable {
    let userId, ispUserId, connectionNo: Int?
    let username: String?
    let userTypeId, connectionTypeId, parentUserId, accountId: Int?
    let profileId: Int?
    let password: String?
    let userPackServiceId: Int
    let packServiceId, packServiceTypeId: Int?
    let packServiceType, packServiceName: String?
    let parentPackServiceId: Int?
    let parentPackServiceName, particulars: String?
    let zoneId: Int?
    let packServicePrice: Double?
    let packServiceInstallCharge, packServiceOthersCharge: Double?
    let activeDate, expireDate, billingStartDate, billingEndDate: String?
    let expireDay, graceDay: Int?
    let lastPayDate: String?
    let isActive, tempInActive, isNoneStop, isDefault: Bool?
    let status: String?
    let enabled: Bool?
    let actualPayAmount, payAmount, saveAmount: Double?
    let methodId: Int?
    let isParent, isUpGrade, isDownGrade, isNew: Bool?
    let isUpdate, isDelete: Bool?
}

// MARK: - PackServiceResponse
struct PackServiceResponse: Codable {
    let resdata: PackServiceResdata?
}

struct PackServiceResdata: Codable {
    let ispservices: String?
}

// MARK: - PackService
struct PackService: Codable {
    let packServiceId: Int?
    let packServiceName: String?
    let packServicePrice: Double?
    let packServiceTypeId: Int?
    let packServiceType: String?
    let parentPackServiceId: Int?
    let parentPackServiceName: String?
    let isChecked: Bool?
    let isParent: Bool?
    let childPackServices: [ChildPackService]?
}

// MARK: - ChildPackService
struct ChildPackService: Codable {
    let packServiceId: Int?
    let packServiceName: String?
    let packServicePrice: Double?
    let packServiceTypeId: Int?
    let packServiceType: String?
    let parentPackServiceId: Int?
    let parentPackServiceName: String?
    let isChecked: Bool?
    let isParent: Bool?
}

// MARK: - NewPackService
struct NewPackService: Codable {
    let userPackServiceId, connectionNo, userId, connectionTypeId: Int?
    let zoneId, accountId, packServiceId: Int?
    let packServiceName: String?
    let parentPackServiceId: Int?
    let parentPackServiceName: String?
    let packServiceTypeId: Int?
    let packServiceType: String?
    let packServicePrice, packServiceInstallCharge, packServiceOthersCharge, payAmount, saveAmount: Double?
    let methodId: Int?
    let isUpGrade, isDownGrade, isDefault: Bool?
    let expireDate, activeDate: String?
    let isNew, isUpdate, isDelete, enabled: Bool?
    let deductBalance: Double?
    let isBalanceDeduct, isActive: Bool?
}

// MARK: - PackUserInfo
struct PackUserInfo: Codable {
    let id, userId: Int?
    let values: String?
    let loggeduserId: Int?
}

// MARK: - NewPackageSave
enum NewPackageSave: Encodable {
    case newPackServiceArray([NewPackService])
    case packUserInfo(PackUserInfo)
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .newPackServiceArray(let x):
            try container.encode(x)
        case .packUserInfo(let x):
            try container.encode(x)
        }
    }
}
