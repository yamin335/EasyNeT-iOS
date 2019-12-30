//
//  DefaultApiResponse.swift
//  Pace Cloud
//
//  Created by rgl on 13/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import Foundation

// MARK: - DefaultAPIResponse
struct DefaultResponse: Codable {
    let resdata: Resdata
}

// MARK: - Resdata
struct Resdata: Codable {
    let message: String?
    let resstate: Bool?
}
