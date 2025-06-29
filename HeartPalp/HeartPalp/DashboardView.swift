import SwiftUI
import Charts
import SpeziHealthKit
import HealthKit
import SpeziHealthKitUI

struct DashboardView: View {
    // MARK: – Four heart‑rate queries
    @HealthKitQuery(.heartRate, timeRange: .today) private var hrTodaySamples
    @HealthKitQuery(.heartRate, timeRange: .currentWeek) private var hrWeekSamples
    @HealthKitQuery(.heartRate, timeRange: .currentMonth) private var hrMonthSamples
    @HealthKitQuery(.heartRate, timeRange: .currentYear) private var hrAllSamples

    @HealthKitQuery(.restingHeartRate, timeRange: .today) private var restingHR
    @HealthKitQuery(.restingHeartRate, timeRange: .currentYear) private var allRestingHR
    
    @HealthKitQuery(.bloodOxygen, timeRange: .today) private var oxygen
    @HealthKitQuery(.bloodOxygen, timeRange: .currentYear) private var allOxygen
    @HealthKitQuery(.electrocardiogram, timeRange: .currentYear) private var ecgSamples
    
    // MARK: – Activity (new)
     @HealthKitQuery(.stepCount, timeRange: .today)         private var steps
     @HealthKitQuery(.stepCount, timeRange: .currentYear)         private var allSteps
     @HealthKitQuery(.activeEnergyBurned, timeRange: .today) private var energy
    @HealthKitQuery(.activeEnergyBurned, timeRange: .currentYear) private var allEnergy
     @HealthKitQuery(.appleExerciseTime, timeRange: .today) private var exercise
    @HealthKitQuery(.appleExerciseTime, timeRange: .currentYear) private var allExercise
     @HealthKitQuery(.appleStandTime, timeRange: .today)    private var stand
    @HealthKitQuery(.appleStandTime, timeRange: .currentYear)    private var allStand

    
    @HealthKitQuery(.bloodGlucose, timeRange: .today) private var glucoseSamples
    @HealthKitQuery(.bloodGlucose, timeRange: .currentYear) private var allGlucoseSamples

    @StateObject private var fhirService = FHIRDataService()
    @State private var showingMeasurementView = false
    @State private var showingSettingsView = false
    @AppStorage("fibriCheckEnabled") private var fibriCheckEnabled = false

    // MARK: – Picker state
    enum Range: String, CaseIterable, Identifiable {
        case today = "Today"
        case week  = "1 Week"
        case month = "1 Month"
        case year  = "1 Year"
        var id: Self { self }
    }
    @State private var selectedRange: Range = .today

    // MARK: – Computed latest values for cards
    private var latestHR: String {
        guard let s = hrTodaySamples.last else { return "--" }
        let bpm = s.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        return "\(Int(bpm)) BPM"
    }
    private var latestResting: String {
        guard let s = restingHR.last else { return "--" }
        let bpm = s.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        return "\(Int(bpm)) BPM"
    }
    private var latestO2: String {
        guard let s = oxygen.last else { return "--" }
        let pct = s.quantity.doubleValue(for: HKUnit.percent()) * 100
        return "\(Int(pct)) %"
    }
   
    private var latestGlucose: String {
        guard let sample = glucoseSamples.last else {
            return "--"
        }

        // 1) mmol/L unit
        let mmolPerLUnit = HKUnit
            .moleUnit(
                with: .milli,
                molarMass: HKUnitMolarMassBloodGlucose
            )
            .unitDivided(by: HKUnit.liter())   // "per L"

        // 2) mg/dL unit
        let mgPerDlUnit = HKUnit
            .gramUnit(with: .milli)               // mg
            .unitDivided(by: HKUnit.literUnit(with: .deci))  // per dL

        // Convert
        let mgdl = sample.quantity.doubleValue(for: mgPerDlUnit)
        return "\(Int(mgdl)) mg/dL"
    }

        private var totalSteps: Int {
            steps.reduce(0) { $0 + Int($1.quantity.doubleValue(for: .count())) }
        }
        private var totalEnergy: Int {
            energy.reduce(0) { $0 + Int($1.quantity.doubleValue(for: .kilocalorie())) }
        }
        private var totalExercise: Int {
            exercise.reduce(0) { $0 + Int($1.quantity.doubleValue(for: .minute())) }
        }
        private var totalStand: Int {
            stand.reduce(0) { $0 + Int($1.quantity.doubleValue(for: .minute())) }
        }

    // MARK: – Pick the right samples for chart
    private var displayedHR: [HKQuantitySample] {
        let all = Array(hrAllSamples)
        switch selectedRange {
        case .today: return Array(hrTodaySamples)
        case .week: return Array(hrWeekSamples)
        case .month: return Array(hrMonthSamples)
        case .year:
            let cutoff = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
            return all.filter { $0.startDate >= cutoff }
        }
    }

    // MARK: – Latest ECG convenience
    private var latestECG: HKElectrocardiogram? {
        ecgSamples.sorted { $0.startDate < $1.startDate }.last
    }
    private let twoColumn = [
         GridItem(.flexible(), spacing: 16),
         GridItem(.flexible(), spacing: 16)
     ]

    // MARK: – Symptom Survey
    struct SymptomSurveySummary {
        let authored: String
        let answers: [String]
        let questions: [String]
    }

    var symptomSurvey: [SymptomSurveySummary] {
        guard let jsonString = UserDefaults.standard.string(forKey: "latestSymptomSurveyResponse"),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let authored = json["authored"] as? String,
              let items = json["item"] as? [[String: Any]] else {
            return []
        }
        var answers: [String] = []
        var questions: [String] = []
        for item in items {
            if let text = item["text"] as? String {
                questions.append("\(text)")
                if let answerArr = item["answer"] as? [[String: Any]], let answer = answerArr.first {
                    if let value = answer["valueString"] as? String {
                        answers.append("\(value)")
                    } else if let value = answer["valueInteger"] {
                        answers.append("\(value)")
                    } else if let value = answer["valueBoolean"] {
                        answers.append("\(value)")
                    } else if let value = answer["valueCoding"] as? [String: Any], let display = value["display"] as? String {
                        answers.append("\(display)")
                    }
                } else {
                    answers.append(text)
                }
            }
        }
        return [SymptomSurveySummary(authored: authored, answers: answers, questions: questions)]
    }

    // Add a state variable to control the presentation of the detail view
    @State private var showingSymptomSurveyDetail = false

    // MARK: – Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Emergency Measurement Button
                    Button(action: {
                        if fibriCheckEnabled {
                            showingMeasurementView = true
                        } else {
                            showingMeasurementView = true
                        }
                    }) {
                        VStack(spacing: 12) {
                            Text(fibriCheckEnabled ? "Continue to FibriCheck Measurement" : "Start Measurement")
                                .font(.headline)
                                .foregroundColor(.white)
                            Image(systemName: "cross.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.teal)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Vital cards
                    VitalCard(
                        title: "Current Heart Rate",
                        value: latestHR,
                        icon: "heart.fill",
                        color: .red,
                        samples: Array(hrTodaySamples)
                    )
                    .padding(.horizontal)
                    
                    // 2) Grid of the other three small cards
                    LazyVGrid(columns: twoColumn, spacing: 16) {
                        VitalCard(
                            title: "Resting HR",
                            value: latestResting,
                            icon: "bed.double.fill",
                            color: .blue,
                            samples: Array(restingHR)
                        )
                        
                        VitalCard(
                            title: "Glucose",
                            value: latestGlucose,
                            icon: "drop.fill",
                            color: .purple,
                            samples: Array(glucoseSamples)
                        )
                        
                        VitalCard(
                            title: "Oxygen Saturation",
                            value: latestO2,
                            icon: "lungs.fill",
                            color: .green,
                            samples: Array(oxygen)
                        )
                        
                        SymptomSurveyCard(summary: symptomSurvey.first)
                            .onTapGesture {
                                showingSymptomSurveyDetail = true
                            }
                            .sheet(isPresented: $showingSymptomSurveyDetail) {
                                SymptomSurveyDetailViewNew(summary: symptomSurvey.first)
                            }
                        
                    }
                    .padding(.horizontal)
                    ActivityRingCard()
                    .padding(.horizontal)
                   

                    Divider()

                    // Range picker
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(Range.allCases) { r in Text(r.rawValue).tag(r) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Chart title & view
                    Text("Heart Rate (\(selectedRange.rawValue))")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if displayedHR.count < 2 {
                        Text("Insufficient data for this period.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        HeartRateChartView(
                            samples: displayedHR,
                            range: selectedRange
                        )
                        .padding(.horizontal)
                    }

                    Divider()

                    // Latest ECG
                    Group {
                        Text("🧠 Latest ECG")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        if let ecg = latestECG {
                            ECGCard(ecg: ecg)
                                .padding(.horizontal)
                        } else {
                            Text("No ECG recordings available.")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }

                    Divider()
                }
                .padding(.vertical)
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettingsView = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }
                .sheet(isPresented: $showingSettingsView) {
                    SettingsView(isPresented: $showingSettingsView)
                }
                .sheet(isPresented: $showingMeasurementView) {
                    NavigationView {
                        if fibriCheckEnabled {
                            FibriCheckMeasurementView(isPresented: $showingMeasurementView)
                        } else {
                            HeartEpisodeMeasurementView(isPresented: $showingMeasurementView)
                        }
                    }
                }
                .onAppear() {
                    Task {
                        do {
                            let lastSync = fhirService.lastSyncDate ?? Date.distantPast
                            print("📊 Dashboard sync check - Last sync: \(lastSync)")
                            
                            // Filter samples to only include those after lastSync
                            let newHRSamples = Array(hrAllSamples.filter { $0.startDate > lastSync })
                            let newRestingSamples = Array(allRestingHR.filter { $0.startDate > lastSync })
                            let newOxygenSamples = Array(allOxygen.filter { $0.startDate > lastSync })
                            let newStepSamples = Array(allSteps.filter { $0.startDate > lastSync })
                            let newEnergySamples = Array(allEnergy.filter { $0.startDate > lastSync })
                            let newExerciseSamples = Array(allExercise.filter { $0.startDate > lastSync })
                            let newStandSamples = Array(allStand.filter { $0.startDate > lastSync })
                            let newGlucoseSamples = Array(allGlucoseSamples.filter { $0.startDate > lastSync })
                            let newECGSamples = Array(ecgSamples.filter { $0.startDate > lastSync })
                            
                            // Log the number of new samples found
                            print("📊 New samples found - HR: \(newHRSamples.count), Resting: \(newRestingSamples.count), Oxygen: \(newOxygenSamples.count), Steps: \(newStepSamples.count), Energy: \(newEnergySamples.count), Exercise: \(newExerciseSamples.count), Stand: \(newStandSamples.count), Glucose: \(newGlucoseSamples.count), ECG: \(newECGSamples.count)")
                            
                            // Only sync if we have new data
                            if !newHRSamples.isEmpty || !newRestingSamples.isEmpty || !newOxygenSamples.isEmpty ||
                               !newStepSamples.isEmpty || !newEnergySamples.isEmpty || !newExerciseSamples.isEmpty ||
                               !newStandSamples.isEmpty || !newGlucoseSamples.isEmpty || !newECGSamples.isEmpty {
                                try await fhirService.uploadAllHealthData(
                                    hrSamples: newHRSamples,
                                    restingSamples: newRestingSamples,
                                    oxygenSamples: newOxygenSamples,
                                    stepSamples: newStepSamples,
                                    energySamples: newEnergySamples,
                                    exerciseSamples: newExerciseSamples,
                                    standSamples: newStandSamples,
                                    glucoseSamples: newGlucoseSamples,
                                    ecgSamples: newECGSamples
                                )
                                fhirService.lastSyncDate = Date()
                                print("📊 Dashboard - Updated lastSyncDate after sync")
                                print("✅ Synced new data since last sync")
                            } else {
                                print("ℹ️ No new data to sync since last sync at \(lastSync)")
                            }
                        } catch {
                            print("❌ Sync failed: \(error)")
                        }
                    }
                }
            }
        }
    }
}
