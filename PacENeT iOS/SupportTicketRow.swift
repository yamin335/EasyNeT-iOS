//
//  SupportTicketRow.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/8/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct SupportTicketRow: View {
    @State var item: SupportTicket
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(item.ticketSummary ?? "Unknown")
                    .font(.headline)
                    .padding(.leading, 16)
                    .lineLimit(2)
                    .foregroundColor(.black)
                Text("No: \(item.ispTicketNo ?? "N/A")")
                    .font(.subheadline)
                    .padding(.leading, 16)
                    .padding(.top, 4)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack {
                Text(item.status ?? "N/A").font(.footnote)
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                    .padding(.trailing, 8)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
            }
            .background(getStatusColor(status: item.status ?? "N/A"))
            .cornerRadius(5)
            .padding()
        }
    }
}

func getStatusColor(status: String) -> Color {
    switch status {
    case "Pending":
        return Color.red
    case "Processing":
        return Color.yellow
    case "Resolved":
        return Color.green
    default:
        return Color.red
    }
}

//struct SupportTicketRow_Previews: PreviewProvider {
//    static var previews: some View {
//        SupportTicketRow()
//    }
//}
