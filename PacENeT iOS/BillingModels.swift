//
//  BillingModels.swift
//  PacENeT iOS
//
//  Created by Yamin on 23/3/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation

// MARK: - Response Models for Foster Payments

// MARK: - FosterResponse
struct FosterResponse: Codable {
    let resdata: FosterResdata
}

// MARK: - FosterResdata
struct FosterResdata: Codable {
    let message: String?
    let resstate: Bool?
    let paymentProcessUrl: String?
    let paymentStatusUrl: String?
    let amount: String?
}

// MARK: - FosterStatusCheckModel
struct FosterStatusCheckModel: Codable {
    let resdata: FosterStatusResdata
}

// MARK: - FosterStatusResdata
struct FosterStatusResdata: Codable {
    let resstate: Bool?
    let fosterRes: String?
}

// MARK: - FosterModel
struct FosterModel: Codable {
    let MerchantTxnNo: String?
    let TxnResponse: String?
    let TxnAmount: String?
    let Currency: String?
    let ConvertionRate: String?
    let OrderNo: String?
    let fosterid: String?
    let hashkey: String?
    let message: String?
}

// MARK: - Response Models for BKash Payments

// MARK: - BKashTokenResponse
struct BKashTokenResponse: Codable {
    let resdata: BKashTokenResdata?
}

// MARK: - BKashTokenResdata
struct BKashTokenResdata: Codable {
    let resstate: Bool?
    let tModel: TModel?
}

// MARK: - TModel
struct TModel: Codable {
    let token: String?
    let appKey: String?
    let currency: String?
    let marchantInvNo: String?
}

struct PaymentRequest : Codable {
    let amount: String?
    let intent: String? = "sale"
    
    init(amount: String?) {
        self.amount = amount
    }
}

// MARK: - BKashCreatePaymentResponse
struct BKashCreatePaymentResponse: Codable {
    let resdata: BKashCreatePaymentResdata?
}

// MARK: - BKashCreatePaymentResdata
struct BKashCreatePaymentResdata : Codable {
    let resstate: Bool?
    let resbKash: String?
}

// MARK: - BKashExecutePaymentResponse
struct BKashExecutePaymentResponse: Codable {
    let resdata: BKashExecutePaymentResdata?
}

// MARK: - BKashExecutePaymentResdata
struct BKashExecutePaymentResdata : Codable {
    let resstate: Bool?
    let resExecuteBk: String?
}
