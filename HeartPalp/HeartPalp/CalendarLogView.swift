//
//  CalendarLogView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
//

import SwiftUI
import SpeziHealthKit
import HealthKit
import SpeziHealthKitUI

struct CalendarLogView: View {
    @State private var selectedDate = Date()
    @HealthKitQuery(.heartRate, timeRange: .currentYear) private var hrAll
    @HealthKitQuery(.restingHeartRate, timeRange: .currentYear) private var restingAll
    @HealthKitQuery(.bloodOxygen, timeRange: .currentYear) private var oxyAll
    @HealthKitQuery(.electrocardiogram,timeRange: .currentYear) private var ecgAll

    var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)

                        DayLogSummaryView(
                            date: selectedDate,
                            hrSamples: Array(hrAll),
                            restingSamples: Array(restingAll),
                            oxygenSamples: Array(oxyAll),
                            ecgSamples: Array(ecgAll)
                        )
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Health Logs")
            }
        }
    }
