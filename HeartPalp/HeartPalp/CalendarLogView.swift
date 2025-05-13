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
    @State private var showingDaysPicker = false
    @State private var selectedDays = 7
    @State private var showingShareSheet = false
    @State private var shareableLink: String = ""
    
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
                    // Shareable Link Button
                    Button(action: {
                        showingDaysPicker = true
                    }) {
                        HStack {
                            Image(systemName: "link")
                            Text("Create Shareable Link")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
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
            .sheet(isPresented: $showingDaysPicker) {
                NavigationView {
                    Form {
                        Section(header: Text("Select Link Validity Period")) {
                            Picker("Days Valid", selection: $selectedDays) {
                                ForEach([1, 3, 7, 14, 30], id: \.self) { days in
                                    Text("\(days) days").tag(days)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                        
                        Section {
                            Button("Generate Link") {
                                generateAndShareLink()
                                showingDaysPicker = false
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                        }
                    }
                    .navigationTitle("Shareable Link")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingDaysPicker = false
                    })
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = URL(string: shareableLink) {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func generateAndShareLink() {
        // Use the FHIR patient ID from your app's configuration
        let patientId = "example-patient-id3" // This should be replaced with your actual patient ID
        shareableLink = LinkGenerator.generateLink(patientId: patientId, daysValid: selectedDays)
        showingShareSheet = true
    }
}

// ShareSheet view for sharing the generated link
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
