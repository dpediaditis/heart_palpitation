//
//  CalendarView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()

    var body: some View {
        VStack(spacing: 12) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)

            // Placeholder log text
            Text("Log for \(selectedDate.formatted(.dateTime.day().month().year()))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}
