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
    let payablePackService: Double?
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
    let isUpdate, isDelete, isChecked: Bool?
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
    let zoneId, accountId, contactId, packId, packServiceId: Int?
    let packServiceName: String?
    let parentPackServiceId: Int?
    let parentPackServiceName: String?
    let packServiceTypeId: Int?
    let packServiceType: String?
    let packServicePrice, packServiceInstallCharge, packServiceOthersCharge, actualPayAmount, payAmount, saveAmount: Double?
    let methodId: Int?
    let isUpGrade, isDownGrade: Bool?
    let expireDate, activeDate: String?
    let isNew, isUpdate, isDelete, enabled: Bool?
    let deductBalance: Double?
    let isBalanceDeduct, isActive, isNoneStop, isDefault: Bool?
}

// MARK: - PackUserInfo
struct PackUserInfo: Codable {
    let id, userId: Int?
    let values: String?
    let loggeduserId: Int?
    let CDate: String?
}

// MARK: - NewPackageSave
enum NewPackageSave: Encodable {
    case newPackServiceArray(NewPackService)
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

// MARK: - PayMethodResponse
struct PayMethodResponse: Codable {
    let resdata: PayMethodResdata?
}

// MARK: - PayMethodResdata
struct PayMethodResdata: Codable {
    let listPaymentMethod: [PayMethod]?
}

// MARK: - PayMethod
struct PayMethod: Codable {
    let methodId: Int
    let methodName: String?
}

// MARK: - PackageChangeConsumeResponse
struct PackageChangeConsumeResponse: Codable {
    let resdata: PackageChangeConsumeData?
}

// MARK: - PackageChangeConsumeData
struct PackageChangeConsumeData: Codable {
    let consumAmount, restAmount: Double?
    let restDays: Int?
    let isPossibleChange, isDue: Bool?
    let message: String?
    let todays: String?
}

struct PackageChangeHelper {
    let isUpgrade: Bool
    let requiredAmount: Double
    let actualPayAmount: Double
    let payAmount: Double
    let savedAmount: Double
    let deductedAmount: Double
}

struct ConnectionInfo: Codable {
    let BalanceAmount: Double?
    let DeductedAmount: Double?
    let UserPackServiceId: Int?
    let accountId: Int?
    let profileId: Int?
    let userName: String?
}

struct ResBkash: Codable {
    let paymentID: String?
    let createTime: String?
    let updateTime: String?
    var trxID: String?
    let transactionStatus: String?
    let amount: String?
    let currency: String?
    let intent: String?
    let merchantInvoiceNumber: String?
    let isSuccess: Bool?
}

// MARK: - NewPackageSaveByBkash
enum NewPackageSaveByBkash: Encodable {
    case pacList(NewPackService)
    case resBkash(ResBkash)
    case packUserInfo(PackUserInfo)
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .pacList(let x):
            try container.encode(x)
        case .resBkash(let x):
            try container.encode(x)
        case .packUserInfo(let x):
            try container.encode(x)
        }
    }
}

// MARK: - NewPackageSaveByFoster
enum NewPackageSaveByFoster: Encodable {
    case pacList(NewPackService)
    case fosterData(FosterModel)
    case packUserInfo(PackUserInfo)
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .pacList(let x):
            try container.encode(x)
        case .fosterData(let x):
            try container.encode(x)
        case .packUserInfo(let x):
            try container.encode(x)
        }
    }
}
