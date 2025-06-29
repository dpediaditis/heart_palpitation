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
    @State private var shareURL: URL? = nil
    
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
            .sheet(isPresented: $showingShareSheet, onDismiss: {
                // Reset the URL when the sheet is dismissed
                shareURL = nil
            }) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    private func generateAndShareLink() {
        print("🔗 Generating shareable link...")
        // Use the FHIR patient ID from app configuration
        let patientId = AppConfig.patientId
        let generatedLink = LinkGenerator.generateLink(patientId: patientId, daysValid: selectedDays)
        print("🔗 Generated link: \(generatedLink)")
        
        // Create URL first
        guard let url = URL(string: generatedLink) else {
            print("❌ Failed to create URL from generated link")
            return
        }
        
        // Update state on the main thread
        DispatchQueue.main.async {
            self.shareableLink = generatedLink
            self.shareURL = url
            print("🔗 Created URL object and updated state")
            
            // Only show the sheet if we have a valid URL
            if self.shareURL != nil {
                print("🔗 Presenting share sheet")
                self.showingShareSheet = true
            }
        }
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
