//
//  ECGCard.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
//

import SwiftUI
import SpeziHealthKit
import HealthKit

struct ECGCard: View {
    let ecg: HKElectrocardiogram
    @State private var voltageValues: [Double] = []
    @State private var isLoading = true
    @State private var showDetailView = false

    var body: some View {
        Button(action: {
            showDetailView = true
        }) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetailView) {
            ECGDetailView(ecg: ecg, voltageValues: voltageValues)
        }
        .task {
            await loadVoltage()
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader
            
            cardClassification
            
            cardWaveform
            
            // Tap indicator
            HStack {
                Spacer()
                Text("Tap for details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var cardHeader: some View {
        HStack {
            Label("ECG Recording", systemImage: "waveform.path.ecg")
                .font(.headline)
            
            Spacer()
            
            Text(ecg.startDate.formatted(.dateTime.day().month().hour().minute()))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var cardClassification: some View {
        HStack {
            Circle()
                .fill(classificationColor)
                .frame(width: 10, height: 10)
            
            Text(classificationText)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if let heartRate = ecg.averageHeartRate?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) {
                Text("\(Int(heartRate)) BPM")
                    .font(.subheadline)
            }
        }
    }
    
    private var cardWaveform: some View {
        Group {
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if voltageValues.isEmpty {
                Text("No ECG data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ECGChartView(data: voltageValues)
                    .frame(height: 120)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }

    var classificationColor: Color {
        switch ecg.classification {
        case .sinusRhythm: return .green
        case .atrialFibrillation: return .red
        default: return .orange
        }
    }

    var classificationText: String {
        switch ecg.classification {
        case .sinusRhythm: return "Sinus Rhythm"
        case .atrialFibrillation: return "Atrial Fibrillation"
        case .inconclusiveLowHeartRate: return "Inconclusive (Low HR)"
        case .inconclusiveHighHeartRate: return "Inconclusive (High HR)"
        case .inconclusivePoorReading: return "Inconclusive (Poor Reading)"
        case .inconclusiveOther: return "Inconclusive"
        default: return "Unknown"
        }
    }

    func loadVoltage() async {
        isLoading = true
        do {
            let store = HKHealthStore()
            var values: [Double] = []
            
            let query = HKElectrocardiogramQuery(ecg) { _, result in
                switch result {
                case .measurement(let measurement):
                    if let voltage = measurement.quantity(for: .appleWatchSimilarToLeadI) {
                        let mv = voltage.doubleValue(for: HKUnit.volt()) * 1000.0
                        values.append(mv)
                    }
                case .done:
                    Task { @MainActor in
                        self.voltageValues = values
                        self.isLoading = false
                    }
                case .error(let error):
                    print("❌ ECG query error:", error)
                    Task { @MainActor in
                        self.isLoading = false
                    }
                }
            }
            
            store.execute(query)
            
        } catch {
            print("❌ ECG error:", error)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// Break up the detail view into separate components
struct ECGDetailView: View {
    let ecg: HKElectrocardiogram
    let voltageValues: [Double]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    WaveformSection(
                        voltageValues: voltageValues,
                        sampleRate: ecg.samplingFrequency?.doubleValue(for: HKUnit.hertz()) ?? 512.0
                    )
                    ClassificationSection(ecg: ecg)
                    RecordingDetailsSection(ecg: ecg, voltageValues: voltageValues)
                    
                    if !voltageValues.isEmpty {
                        WaveformStatsSection(voltageValues: voltageValues)
                    }
                }
                .padding()
            }
            .navigationTitle("ECG Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Individual sections for the detail view
struct WaveformSection: View {
    let voltageValues: [Double]
    let sampleRate: Double
    
    init(voltageValues: [Double], sampleRate: Double = 512.0) {
        self.voltageValues = voltageValues
        self.sampleRate = sampleRate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ECG Waveform")
                .font(.headline)
            
            if voltageValues.isEmpty {
                Text("No waveform data available")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Scroll horizontally to view the entire recording")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ECGChartView(data: voltageValues, sampleRate: sampleRate)
                        .frame(height: 200)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct ClassificationSection: View {
    let ecg: HKElectrocardiogram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Classification")
                .font(.headline)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(classificationColor)
                    .frame(width: 16, height: 16)
                
                Text(classificationText)
                    .font(.title3)
            }
            
            Text(classificationDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    var classificationColor: Color {
        switch ecg.classification {
        case .sinusRhythm: return .green
        case .atrialFibrillation: return .red
        default: return .orange
        }
    }

    var classificationText: String {
        switch ecg.classification {
        case .sinusRhythm: return "Sinus Rhythm"
        case .atrialFibrillation: return "Atrial Fibrillation"
        case .inconclusiveLowHeartRate: return "Inconclusive (Low HR)"
        case .inconclusiveHighHeartRate: return "Inconclusive (High HR)"
        case .inconclusivePoorReading: return "Inconclusive (Poor Reading)"
        case .inconclusiveOther: return "Inconclusive"
        default: return "Unknown"
        }
    }
    
    var classificationDescription: String {
        switch ecg.classification {
        case .sinusRhythm:
            return "A sinus rhythm result means the heart was beating in a uniform pattern between 50-100 BPM."
        case .atrialFibrillation:
            return "Atrial fibrillation is an irregular heart rhythm where the upper chambers beat out of sync with the lower chambers."
        case .inconclusiveLowHeartRate:
            return "The heart rate was below 50 BPM, which makes it difficult to determine the heart rhythm."
        case .inconclusiveHighHeartRate:
            return "The heart rate was above 150 BPM, which makes it difficult to determine the heart rhythm."
        case .inconclusivePoorReading:
            return "The recording couldn't be classified due to poor signal quality."
        case .inconclusiveOther:
            return "The recording couldn't be classified for various reasons."
        default:
            return "The classification of this ECG is unknown."
        }
    }
}

struct RecordingDetailsSection: View {
    let ecg: HKElectrocardiogram
    let voltageValues: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recording Details")
                .font(.headline)
            
            detailRow(label: "Date", value: ecg.startDate.formatted(.dateTime.day().month().year()))
            detailRow(label: "Time", value: ecg.startDate.formatted(.dateTime.hour().minute()))
            
            if let heartRate = ecg.averageHeartRate?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) {
                detailRow(label: "Average Heart Rate", value: "\(Int(heartRate)) BPM")
            }
            
            detailRow(label: "Sampling Frequency", value: "\(Int(ecg.samplingFrequency?.doubleValue(for: HKUnit.hertz()) ?? 0)) Hz")
            detailRow(label: "Number of Voltages", value: "\(voltageValues.count) points")
            detailRow(label: "Symptoms Reported", value: ecg.symptomsStatus == .present ? "Yes" : "No")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct WaveformStatsSection: View {
    let voltageValues: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Waveform Statistics")
                .font(.headline)
            
            let stats = calculateStats(voltageValues)
            detailRow(label: "Min Voltage", value: String(format: "%.2f mV", stats.min))
            detailRow(label: "Max Voltage", value: String(format: "%.2f mV", stats.max))
            detailRow(label: "Average", value: String(format: "%.2f mV", stats.avg))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    private func calculateStats(_ values: [Double]) -> (min: Double, max: Double, avg: Double) {
        guard !values.isEmpty else { return (0, 0, 0) }
        let min = values.min() ?? 0
        let max = values.max() ?? 0
        let avg = values.reduce(0, +) / Double(values.count)
        return (min, max, avg)
    }
}

