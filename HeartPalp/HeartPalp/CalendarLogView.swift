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
    @HealthKitQuery(.stepCount, timeRange: .currentYear) private var stepsAll
     @HealthKitQuery(.activeEnergyBurned, timeRange: .currentYear) private var energyAll
     @HealthKitQuery(.appleExerciseTime, timeRange: .currentYear) private var exerciseAll
     @HealthKitQuery(.appleStandTime, timeRange: .currentYear) private var standAll
     @HealthKitQuery(.bloodGlucose, timeRange: .currentYear) private var glucoseAll
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
                            ecgSamples: Array(ecgAll),
                            stepSamples:     Array(stepsAll),
                            energySamples:   Array(energyAll),
                            exerciseSamples: Array(exerciseAll),
                            standSamples:    Array(standAll),
                            glucoseSamples:  Array(glucoseAll)
                        )
                    }
                    .padding(.vertical)
                }
                .navigationTitle("Health Logs")
            }
        }
    }
