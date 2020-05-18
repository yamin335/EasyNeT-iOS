//
//  SupportModels.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/8/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation

// MARK: - SupportTicketResponse
struct SupportTicketResponse: Codable {
    let resdata: SupportTicketResdata?
}

// MARK: - SupportTicketResdata
struct SupportTicketResdata: Codable {
    let listCrmIspTicket: [SupportTicket]?
    let recordsTotal: Int?
}

// MARK: - SupportTicket
struct SupportTicket: Codable {
    let ispTicketId, ispTicketCategoryId: Int?
    let ispTicketNo: String?
    let ispUserId: Int?
    let ticketSummary: String?
    let attachedFile: String?
    let ticketDescription: String?
    let isResolved, isProcessed: Bool?
    let ispUserName: String?
    let ticketCategory, status: String?
    let isActive: Bool?
    let companyId: Int?
    let createDate: String?
    let createdBy: String?
    let listIspTicketConversation, listIspTicketAttachment: String?
}

// MARK: - SupportTicketDetailResponse
struct SupportTicketDetailResponse: Codable {
    let resdata: TicketDetailResdata?
}

// MARK: - TicketDetailResdata
struct TicketDetailResdata: Codable {
    let objCrmIspTicket: ObjCRMISPTicket?
}

// MARK: - ObjCRMISPTicket
struct ObjCRMISPTicket: Codable {
    let ispTicketId, ispTicketCategoryId: Int?
    let ispTicketNo: String?
    let ispUserId: Int?
    let ticketSummary: String?
    let attachedFile: String?
    let ticketDescription: String?
    let isResolved: Bool?
    let isProcessed: Bool?
    let ispUserName: String?
    let ticketCategory, status: String?
    let isActive: Bool?
    let companyId: Int?
    let createDate: String?
    let createdBy: String?
    let listIspTicketConversation: [ISPTicketConversation]?
    let listIspTicketAttachment: [ISPTicketAttachment]?
}

// MARK: - ISPTicketAttachment
struct ISPTicketAttachment: Codable {
    let ispTicketAttachmentId, ispTicketId: Int?
    let attachedFile: String?
    let isActive: Bool?
    let companyId: Int?
    let createDate: String?
    let createdBy: Int?
}

// MARK: - ISPTicketConversation
struct ISPTicketConversation: Codable {
    let ispTicketConversationId, ispTicketId, ispUserId: Int?
    let systemUserId: String?
    let userFullName, ticketComment: String?
    let parentCommentId: Int?
    let attachedFile: String?
    let isActive: Bool?
    let companyId: Int?
    let createDate: String?
    let createdBy: Int?
}

// MARK: - TicketCategoryResponse
struct TicketCategoryResponse: Codable {
    let resdata: TicketCategoryResdata?
}

// MARK: - TicketCategoryResdata
struct TicketCategoryResdata: Codable {
    let listTicketCategory: [TicketCategory]?
}

// MARK: - TicketCategory
struct TicketCategory: Codable {
    let ispTicketCategoryId: Int
    let ticketCategory: String?
}

// MARK: - ImageData
struct ImageData: Hashable {
    let data: Data
    let name: String
    let size: String
    
    init(image: Data, name: String, size: String) {
        self.data = image
        self.name = name
        self.size = size
    }
}
