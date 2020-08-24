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

extension String {
    func formatDate() -> String {
        let months = [0 : "", 1 : "Jan", 2 : "Feb", 3 : "Mar", 4 : "Apr", 5 : "May", 6 : "Jun", 7 : "Jul", 8 : "Aug", 9 : "Sep", 10 : "Oct", 11 : "Nov", 12 : "Dec"]
        if self.contains("T") {
            let splits = self.split(separator: "T")

            let tempSplits = (splits.count > 1 ? splits[0] : "").split(separator: "-")

            return "\(tempSplits[2]) \(months[Int(tempSplits[1]) ?? 0] ?? ""), \(tempSplits[0])"
        } else {
            let tempSplits = self.split(separator: "-")

            if tempSplits.count > 2 {
                return "\(tempSplits[2]) \(months[Int(tempSplits[1]) ?? 0] ?? ""), \(tempSplits[0])"
            } else {
                return ""
            }
        }
    }
}

extension String {
    func formatTime() -> String {
        if self.contains("T") {
            let tempStringArray = self.split(separator: "T")
            var tempString1 = tempStringArray[1]
            var hour = 0
            var minute = 0
            //var seconds = 0
            var amPm = ""
            if (tempString1.contains(".")){
                tempString1 = tempString1.split(separator: ".")[0]
                hour = Int(tempString1.split(separator: ":")[0]) ?? 0
                minute = Int(tempString1.split(separator: ":")[1]) ?? 0
                //seconds = Int(tempString1.split(separator: ":")[2]) ?? 0
                amPm = ""
                if hour > 12 {
                    hour -= 12
                    amPm = "PM"
                } else if hour == 0 {
                    hour += 12
                    amPm = "AM"
                } else if hour == 12 {
                    amPm = "PM"
                } else {
                    amPm = "AM"
                }
            } else {
                hour = Int(tempString1.split(separator: ":")[0]) ?? 0
                minute = Int(tempString1.split(separator: ":")[1]) ?? 0
                //seconds = Int(tempString1.split(separator: ":")[2]) ?? 0
                amPm = ""
                if hour > 12 {
                    hour -= 12
                    amPm = "PM"
                } else if hour == 0 {
                    hour += 12
                    amPm = "AM"
                } else if hour == 12 {
                    amPm = "PM"
                } else {
                    amPm = "AM"
                }
            }
            return "\(hour):\(minute) \(amPm)"
        }
        return ""
    }
}


