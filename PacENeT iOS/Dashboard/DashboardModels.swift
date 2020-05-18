//
//  DashboardModels.swift
//  PacENeT iOS
//
//  Created by Yamin on 19/3/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation

// MARK: - Welcome
struct DashSessionResponse: Codable {
    let resdata: DashSessionResdata
}

// MARK: - Resdata
struct DashSessionResdata: Codable {
    let sessionChartData: [SessionChartData]
}

// MARK: - SessionChartDatum
struct SessionChartData: Codable {
    let dataValueUp, dataValueDown: Double
    let dataName: String
}
