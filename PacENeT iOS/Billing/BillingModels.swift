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
    let tModel: TModel?
}

// MARK: - TModel
struct TModel: Codable {
    let token: String?
    let appKey: String?
    let currency: String?
    let marchantInvNo: String?
    let idtoken: String?
    let tokentype: String?
    let refreshtoken: String?
    let expiresin: Int?
}

struct PaymentRequest : Codable {
    let amount: String
    let intent = "sale"
    
    init(amount: String) {
        self.amount = amount
    }
}

// MARK: - BKashCreatePaymentResponse
struct BKashCreatePaymentResponse: Codable {
    let resdata: BKashCreatePaymentResdata?
}

// MARK: - BKashCreatePaymentResdata
struct BKashCreatePaymentResdata : Codable {
    let resbKash: String?
    let message: String?
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

// MARK: - InvoiceResponse
struct InvoiceResponse : Codable {
    let resdata: InvoiceResdata?
}

// MARK: - InvoiceResdata
struct InvoiceResdata : Codable {
    let userinvoiceList: String?
    let recordsTotal: Int?
}

// MARK: - Invoice
struct Invoice: Codable {
    let ispInvoiceParentId, ispUserID: Int?
    let fullName, emailAddr, address, phoneNumber: String?
    let userCode, invoiceNo, genMonth, invoiceDate: String?
    let invoiceTotal, taxAmount, discountAmount, dueAmount: Double?
    let grandTotal: Double?
    let paymentStatus: String?
    let isPaid: Bool?
    let fromDate, toDate, createDate, dueAmountInWord: String?
    let recordsTotal: Int?
}

// MARK: - InvoiceDetailResponse
struct InvoiceDetailResponse : Codable {
    let resdata: InvoiceDetailResdata?
}

// MARK: - InvoiceDetailResdata
struct InvoiceDetailResdata : Codable {
    let userinvoiceDetail: String?
}

// MARK: - InvoiceDetail
struct InvoiceDetail: Codable {
    let UserPackServiceChangeID, ISPInvoiceID: Int?
    let isChanged:Bool?
    let packageId: Int?
    let packageName: String?
    let packagePrice: Double?
    let srvStartDate: String?
    let srvEndDate: String?
    let isFirstInv: Bool?
    let installCharge: Double?
    let othersCharge: Double?
}

// MARK: - ChildInvoiceResponse
struct ChildInvoiceResponse : Codable {
    let resdata: ChildInvoiceResdata?
}

// MARK: - ChildInvoiceResdata
struct ChildInvoiceResdata : Codable {
    let userChildInvoiceDetail: String?
}

// MARK: - ChildInvoice
struct ChildInvoice: Codable {
    let id = UUID()
    let ispInvoiceParentId, ispInvoiceId, ispUserID, userPackServiceId: Int?
    let packageId: Int?
    let packageName, fullName, emailAddr, address: String?
    let phoneNumber, userCode, invoiceNo, genMonth: String?
    let invoiceDate: String?
    let invoiceTotal, taxAmount, discountAmount, dueAmount: Double?
    let grandTotal: Double?
    let isPaid: Bool?
    let fromDate, toDate, createDate, dueAmountInWord: String?
}

// MARK: - PayHistResponse
struct PayHistResponse: Codable {
    let resdata: PayHistResdata?
}

// MARK: - PayHistResdata
struct PayHistResdata: Codable {
    let listPayment: String?
}

// MARK: - PayHist
struct PayHist: Codable {
    let ispPaymentID, ispUserID: Int?
    let paidAmount: Double?
    let paymentStatus: String?
    let invoiceNo: Int?
    let transactionDate: String?
    let recordsTotal: Int?
}

// MARK: - UserBalanceResponse
struct UserBalanceResponse: Codable {
    let resdata: UserBalanceResdata?
}

// MARK: - UserBalanceResdata
struct UserBalanceResdata: Codable {
    let billIspUserBalance: UserBalance?
}

// MARK: - UserBalance
struct UserBalance: Codable {
    let ispuserId, balanceAmount: Double?
    let duesAmount: Double?
    let isActive: Bool?
    let companyId: Int?
    let createDate: String?
    let createdBy: Int?
}

// MARK: - BillPaymentHelper
struct BillPaymentHelper {
    let balanceAmount: Double
    let deductedAmount: Double
    let invoiceId : Int
    let userPackServiceId : Int
    let canModify: Bool
    let isChildInvoice: Bool
}

// MARK: - FosterHelper
struct FosterHelper {
    let fosterProcessUrl: String
    let fosterStatusUrl: String
}

struct BkashResData {
    let tmodel: TModel?
    let resBkash: String?
}
