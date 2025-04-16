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
    
    var body: some View {
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

struct ConsentLogView: View {
    @ObservedObject var consentStore: ConsentStore
    @State private var selectedConsent: Consent?
    @State private var showWithdrawAlert = false
    var body: some View {
        NavigationView {
            List(consentStore.consents.sorted { $0.dateGiven > $1.dateGiven }) { consent in
                Button(action: {
                    if consent.isActive {
                        selectedConsent = consent
                        showWithdrawAlert = true
                    }
                }) {
                    VStack(alignment: .leading) {
                        Text("Data Types: \(consent.dataTypes.map { $0.rawValue }.joined(separator: ", "))")
                            .font(.subheadline)
                        Text("From: \(consent.startDate.formatted(date: .abbreviated, time: .shortened)) To: \(consent.endDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.subheadline)
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
                        if let tx = consent.bankIDTransactionID {
                            Text("BankID TX: \(tx)").font(.caption2).foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!consent.isActive)
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
        }
    }
    
    private func withdrawConsent(_ consent: Consent) {
        var revoked = consent
        revoked.status = .revoked
        consentStore.updateConsent(revoked)
    }
}

struct DataTypeSelectionView: View {
    let allTypes: [HKSampleType]
    @Binding var selectedTypes: Set<HKSampleType>
    var onDone: () -> Void
    
    var body: some View {
        NavigationView {
            List(allTypes, id: \.self) { type in
                Toggle(type.localizedName, isOn: Binding(
                    get: { selectedTypes.contains(type) },
                    set: { isOn in
                        if isOn { selectedTypes.insert(type) } else { selectedTypes.remove(type) }
                    }
                ))
            }
            .navigationTitle("Select Data Types")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
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
                return "Distance Walking + Running"
            default:
                return quantityType.identifier
            }
        }
        return self.identifier
    }
}

extension Consent {
    var isActive: Bool {
        status == .authorized && Date() >= startDate && Date() <= endDate
    }
}
