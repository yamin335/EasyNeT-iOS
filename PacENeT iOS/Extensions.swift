//
//  Extensions.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/17/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI
import Foundation
import Combine

extension Double {
    func rounded(toPlaces digits: Int) -> String {
        return String(format: "%.\(digits)f", self)
    }
}


