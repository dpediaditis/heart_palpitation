//
//  ContentView.swift
//  PatAppPlayground
//
//  Created by Anton Styrefors Sparby on 2025-04-16.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @StateObject private var consentStore = ConsentStore()
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var selectedTypes: Set<HKSampleType> = []
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var isAuthorizing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showTypeSelection = false
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            TabView {
                NavigationView {
                    Form {
                        Section(header: Text("Data Types to Share")) {
                            Button(action: { showTypeSelection = true }) {
                                HStack {
                                    Text(selectedTypes.isEmpty ? "Select Data Types" : selectedTypes.map { $0.localizedName }.joined(separator: ", "))
                                        .foregroundColor(selectedTypes.isEmpty ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                            .sheet(isPresented: $showTypeSelection) {
                                DataTypeSelectionView(
                                    allTypes: healthKitManager.supportedTypes,
                                    selectedTypes: $selectedTypes,
                                    onDone: { showTypeSelection = false }
                                )
                            }
                        }
                        Section(header: Text("Select Time Window")) {
                            DatePicker("Start Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            DatePicker("End Date", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                        }
                        Section {
                            Button(action: requestConsent) {
                                if isAuthorizing {
                                    ProgressView()
                                } else {
                                    Text("Share with BankID Consent")
                                }
                            }
                            .disabled(selectedTypes.isEmpty || isAuthorizing)
                        }
                        if let errorMessage {
                            Section {
                                Text(errorMessage).foregroundColor(.red)
                            }
                        }
                    }
                    .navigationTitle("Share Health Data")
                    .alert(isPresented: $showSuccess) {
                        Alert(title: Text("Consent Authorized"), message: Text("Your consent has been saved."), dismissButton: .default(Text("OK")))
                    }
                    .onAppear {
                        healthKitManager.requestAuthorization { _ in }
                    }
                }
                .tabItem {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                ConsentLogView(consentStore: consentStore)
                    .tabItem {
                        Label("Consent Log", systemImage: "clock")
                    }
                
                ConditionServicesView()
                    .tabItem {
                        Label("Services", systemImage: "heart.text.square")
                    }
            }
        } else {
            LoginView(isAuthenticated: $isAuthenticated)
        }
    }
    
    private func requestConsent() {
        isAuthorizing = true
        errorMessage = nil
        let typeIDs = selectedTypes.map { HKSampleTypeIdentifier($0) }
        let consent = Consent(dataTypes: typeIDs, startDate: startDate, endDate: endDate)
        BankIDAuthorizationManager.shared.authorize { success, transactionID in
            isAuthorizing = false
            if success {
                var authorizedConsent = consent
                authorizedConsent.status = .authorized
                authorizedConsent.bankIDTransactionID = transactionID
                consentStore.addConsent(authorizedConsent)
                showSuccess = true
            } else {
                errorMessage = "BankID authorization failed."
            }
        }
    }
}

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("PatApp Playground")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Secure Health Data Sharing")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
                .frame(height: 40)
            
            Button(action: authenticate) {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login with BankID")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isAuthenticating)
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private func authenticate() {
        isAuthenticating = true
        errorMessage = nil
        
        BankIDAuthorizationManager.shared.authorize { success, _ in
            isAuthenticating = false
            if success {
                isAuthenticated = true
            } else {
                errorMessage = "BankID authentication failed. Please try again."
            }
        }
    }
}

struct ConsentLogView: View {
    @ObservedObject var consentStore: ConsentStore
    @State private var selectedConsent: Consent?
    @State private var showWithdrawAlert = false
    @State private var showExportAlert = false
    @State private var exportError: String?
    
    var body: some View {
        NavigationView {
            List(consentStore.consents.sorted { $0.dateGiven > $1.dateGiven }) { consent in
                VStack(alignment: .leading) {
                    Button(action: {
                        if consent.isActive {
                            selectedConsent = consent
                            showWithdrawAlert = true
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text("Shared Data:")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            ForEach(consent.dataTypes, id: \.self) { dataType in
                                HStack {
                                    Image(systemName: getIcon(for: dataType))
                                        .foregroundColor(.blue)
                                    Text(getDescription(for: dataType))
                                        .font(.subheadline)
                                }
                                .padding(.leading)
                            }
                            
                            Text("Time Period:")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                            
                            Text("From: \(consent.startDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .padding(.leading)
                            
                            Text("To: \(consent.endDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.subheadline)
                                .padding(.leading)
                            
                            HStack {
                                Text("Status: \(consent.status.rawValue.capitalized)")
                                    .font(.footnote)
                                    .foregroundColor(consent.status == .authorized ? .green : .red)
                                Spacer()
                                if consent.isActive {
                                    Text("Active")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                } else {
                                    Text("Expired")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 4)
                            
                            if let tx = consent.bankIDTransactionID {
                                Text("BankID TX: \(tx)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!consent.isActive)
                    
                    if consent.isActive {
                        Button(action: {
                            exportConsentData(consent)
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Data")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Consent Log")
            .alert("Withdraw Consent?", isPresented: $showWithdrawAlert, presenting: selectedConsent) { consent in
                Button("Withdraw", role: .destructive) {
                    withdrawConsent(consent)
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("Are you sure you want to withdraw this active consent? This action cannot be undone.")
            }
            .alert("Export Error", isPresented: .constant(exportError != nil)) {
                Button("OK", role: .cancel) {
                    exportError = nil
                }
            } message: {
                if let error = exportError {
                    Text(error)
                }
            }
        }
    }
    
    private func getIcon(for dataType: HKSampleTypeIdentifier) -> String {
        switch dataType.rawValue {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return "figure.walk"
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return "heart.fill"
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return "flame.fill"
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return "figure.walk"
        default:
            return "heart.text.square"
        }
    }
    
    private func getDescription(for dataType: HKSampleTypeIdentifier) -> String {
        switch dataType.rawValue {
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return "Step Count (from Health app)"
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return "Heart Rate (from Health app)"
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return "Active Energy Burned (from Health app)"
        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return "Walking + Running Distance (from Health app)"
        default:
            return "\(dataType.rawValue) (from Health app)"
        }
    }
    
    private func withdrawConsent(_ consent: Consent) {
        var revoked = consent
        revoked.status = .revoked
        consentStore.updateConsent(revoked)
    }
    
    private func exportConsentData(_ consent: Consent) {
        let healthKitManager = HealthKitManager.shared
        
        // Create CSV header
        var csvString = "Timestamp,Data Type,Value,Unit\n"
        
        // Query HealthKit data for each consented type
        for dataType in consent.dataTypes {
            // Convert HKSampleTypeIdentifier to HKQuantityTypeIdentifier
            let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: dataType.rawValue)
            guard let sampleType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) else { continue }
            
            let predicate = HKQuery.predicateForSamples(
                withStart: consent.startDate,
                end: consent.endDate,
                options: .strictStartDate
            )
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    DispatchQueue.main.async {
                        exportError = "Failed to export data: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else { return }
                
                for sample in samples {
                    let value = sample.quantity.doubleValue(for: HKUnit.count())
                    let timestamp = sample.startDate.formatted(.iso8601)
                    // TODO: Handle units properly for different quantity types
                    // Currently using "count" as a placeholder
                    let unit = "count"
                    
                    csvString += "\(timestamp),\(dataType.rawValue),\(value),\(unit)\n"
                }
                
                // Save CSV file
                let fileName = "health_data_\(consent.startDate.formatted(.iso8601))_to_\(consent.endDate.formatted(.iso8601)).csv"
                let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                do {
                    try csvString.write(to: path, atomically: true, encoding: .utf8)
                    
                    DispatchQueue.main.async {
                        let activityVC = UIActivityViewController(
                            activityItems: [path],
                            applicationActivities: nil
                        )
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            rootVC.present(activityVC, animated: true)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        exportError = "Failed to save CSV file: \(error.localizedDescription)"
                    }
                }
            }
            
            healthKitManager.requestAuthorization { _ in
                HKHealthStore().execute(query)
            }
        }
    }
}

struct DataTypeSelectionView: View {
    let allTypes: [HKSampleType]
    @Binding var selectedTypes: Set<HKSampleType>
    var onDone: () -> Void
    @State private var selectedTypeForInfo: HKSampleType?
    
    private var groupedTypes: [(source: String, types: [HKSampleType])] {
        var groups: [String: [HKSampleType]] = [:]
        
        for type in allTypes {
            let source = getSource(for: type)
            groups[source, default: []].append(type)
        }
        
        return groups.map { (source: $0.key, types: $0.value) }
            .sorted { $0.source < $1.source }
    }
    
    private func getSource(for type: HKSampleType) -> String {
        if let quantityType = type as? HKQuantityType {
            switch quantityType.identifier {
            case HKQuantityTypeIdentifier.stepCount.rawValue,
                 HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                return "Activity Data"
            case HKQuantityTypeIdentifier.heartRate.rawValue,
                 HKQuantityTypeIdentifier.restingHeartRate.rawValue,
                 HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue,
                 HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
                 HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
                 HKQuantityTypeIdentifier.vo2Max.rawValue:
                return "Heart Health"
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
                 HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
                return "Energy & Fitness"
            case HKQuantityTypeIdentifier.heartRateRecoveryOneMinute.rawValue:
                return "Heart Rate Recovery"
            default:
                return "Other Health Data"
            }
        }
        return "Other Health Data"
    }
    
    private func getDeviceSource(for type: HKSampleType) -> String {
        if let quantityType = type as? HKQuantityType {
            switch quantityType.identifier {
            case HKQuantityTypeIdentifier.heartRate.rawValue,
                 HKQuantityTypeIdentifier.restingHeartRate.rawValue,
                 HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue,
                 HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
                 HKQuantityTypeIdentifier.vo2Max.rawValue,
                 HKQuantityTypeIdentifier.heartRateRecoveryOneMinute.rawValue:
                return "Collected from Apple Watch"
            case HKQuantityTypeIdentifier.bodyMass.rawValue,
                 HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
                 HKQuantityTypeIdentifier.bodyFatPercentage.rawValue,
                 HKQuantityTypeIdentifier.leanBodyMass.rawValue,
                 HKQuantityTypeIdentifier.height.rawValue,
                 HKQuantityTypeIdentifier.waistCircumference.rawValue,
                 HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
                 HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue,
                 HKQuantityTypeIdentifier.bloodGlucose.rawValue,
                 HKQuantityTypeIdentifier.bodyTemperature.rawValue,
                 HKQuantityTypeIdentifier.respiratoryRate.rawValue:
                return "Collected from iPhone or manually entered"
            case HKQuantityTypeIdentifier.stepCount.rawValue,
                 HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
                 HKQuantityTypeIdentifier.distanceCycling.rawValue,
                 HKQuantityTypeIdentifier.distanceSwimming.rawValue,
                 HKQuantityTypeIdentifier.distanceWheelchair.rawValue,
                 HKQuantityTypeIdentifier.flightsClimbed.rawValue,
                 HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
                 HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
                return "Collected from both Apple Watch and iPhone"
            case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue,
                 HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue,
                 HKQuantityTypeIdentifier.dietaryProtein.rawValue,
                 HKQuantityTypeIdentifier.dietaryFatTotal.rawValue,
                 HKQuantityTypeIdentifier.dietarySugar.rawValue,
                 HKQuantityTypeIdentifier.dietaryFiber.rawValue,
                 HKQuantityTypeIdentifier.dietarySodium.rawValue:
                return "Manually entered data"
            default:
                return "Collected from iPhone"
            }
        }
        return "Collected from iPhone"
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedTypes, id: \.source) { group in
                    Section(header: Text(group.source)) {
                        ForEach(group.types, id: \.self) { type in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { selectedTypes.contains(type) },
                                    set: { isOn in
                                        if isOn { selectedTypes.insert(type) } else { selectedTypes.remove(type) }
                                    }
                                )) {
                                    HStack {
                                        Text(type.localizedName)
                                        Button(action: { selectedTypeForInfo = type }) {
                                            Image(systemName: "info.circle")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Data Types")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
            .alert("Data Source", isPresented: .constant(selectedTypeForInfo != nil), presenting: selectedTypeForInfo) { type in
                Button("Close", role: .cancel) {
                    selectedTypeForInfo = nil
                }
            } message: { type in
                Text(getDeviceSource(for: type))
            }
        }
    }
}

struct ConditionServicesView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Available Services")) {
                    Button(action: openFibriCheck) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Heart Palpitation")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Condition Services")
        }
    }
    
    private func openFibriCheck() {
        if let url = URL(string: "fibricheck://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // If FibriCheck is not installed, open App Store
                if let appStoreURL = URL(string: "https://apps.apple.com/app/fibricheck/id1099556841") {
                    UIApplication.shared.open(appStoreURL)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension HKSampleType {
    var localizedName: String {
        if let quantityType = self as? HKQuantityType {
            switch quantityType.identifier {
            case HKQuantityTypeIdentifier.stepCount.rawValue:
                return "Step Count"
            case HKQuantityTypeIdentifier.heartRate.rawValue:
                return "Heart Rate"
            case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                return "Active Energy Burned"
            case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                return "Walking + Running Distance"
            case HKQuantityTypeIdentifier.restingHeartRate.rawValue:
                return "Resting Heart Rate"
            case HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue:
                return "Walking Heart Rate"
            case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
                return "Heart Rate Variability (HRV)"
            case HKQuantityTypeIdentifier.oxygenSaturation.rawValue:
                return "Blood Oxygen (SpO2)"
            case HKQuantityTypeIdentifier.vo2Max.rawValue:
                return "VO2 Max (Cardio Fitness)"
            case HKQuantityTypeIdentifier.heartRateRecoveryOneMinute.rawValue:
                return "Heart Rate Recovery (1 min)"
            case HKQuantityTypeIdentifier.bodyMass.rawValue:
                return "Body Weight"
            case HKQuantityTypeIdentifier.bodyMassIndex.rawValue:
                return "Body Mass Index (BMI)"
            case HKQuantityTypeIdentifier.bodyFatPercentage.rawValue:
                return "Body Fat Percentage"
            case HKQuantityTypeIdentifier.leanBodyMass.rawValue:
                return "Lean Body Mass"
            case HKQuantityTypeIdentifier.height.rawValue:
                return "Height"
            case HKQuantityTypeIdentifier.waistCircumference.rawValue:
                return "Waist Circumference"
            case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue:
                return "Blood Pressure (Systolic)"
            case HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
                return "Blood Pressure (Diastolic)"
            case HKQuantityTypeIdentifier.bloodGlucose.rawValue:
                return "Blood Glucose"
            case HKQuantityTypeIdentifier.bodyTemperature.rawValue:
                return "Body Temperature"
            case HKQuantityTypeIdentifier.respiratoryRate.rawValue:
                return "Respiratory Rate"
            case HKQuantityTypeIdentifier.distanceCycling.rawValue:
                return "Cycling Distance"
            case HKQuantityTypeIdentifier.distanceSwimming.rawValue:
                return "Swimming Distance"
            case HKQuantityTypeIdentifier.distanceWheelchair.rawValue:
                return "Wheelchair Distance"
            case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
                return "Flights of Stairs Climbed"
            case HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
                return "Basal Energy Burned"
            case HKQuantityTypeIdentifier.dietaryEnergyConsumed.rawValue:
                return "Dietary Energy (Calories)"
            case HKQuantityTypeIdentifier.dietaryCarbohydrates.rawValue:
                return "Dietary Carbohydrates"
            case HKQuantityTypeIdentifier.dietaryProtein.rawValue:
                return "Dietary Protein"
            case HKQuantityTypeIdentifier.dietaryFatTotal.rawValue:
                return "Dietary Total Fat"
            case HKQuantityTypeIdentifier.dietarySugar.rawValue:
                return "Dietary Sugar"
            case HKQuantityTypeIdentifier.dietaryFiber.rawValue:
                return "Dietary Fiber"
            case HKQuantityTypeIdentifier.dietarySodium.rawValue:
                return "Dietary Sodium"
            default:
                return quantityType.identifier.replacingOccurrences(of: "HKQuantityTypeIdentifier", with: "")
                    .replacingOccurrences(of: "RawValue", with: "")
                    .split(by: .uppercaseLetters)
                    .joined(separator: " ")
            }
        }
        return self.identifier
    }
}

// Helper extension to split camelCase strings
extension String {
    func split(by characterSet: CharacterSet) -> [String] {
        var words: [String] = []
        var currentWord = ""
        
        for char in self {
            if characterSet.contains(char.unicodeScalars.first!) {
                if !currentWord.isEmpty {
                    words.append(currentWord)
                    currentWord = ""
                }
            }
            currentWord.append(char)
        }
        
        if !currentWord.isEmpty {
            words.append(currentWord)
        }
        
        return words
    }
}

extension Consent {
    var isActive: Bool {
        status == .authorized && Date() >= startDate && Date() <= endDate
    }
}

// Add this extension to make HKSampleType conform to Identifiable for popover
extension HKSampleType: Identifiable {
    public var id: String { identifier }
}
