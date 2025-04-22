import SwiftUI
import HealthKit
import SpeziHealthKit
import UIKit

/// A single timestamp/value for export
struct DayPoint: Codable {
    let time: Date
    let value: Double
}

/// Shows the day’s summary with averages, latest ECG, and lets you share a CSV including full data & ECG waveform
struct DayLogSummaryView: View {
    // MARK: Inputs
    let date: Date
    let hrSamples: [HKQuantitySample]
    let restingSamples: [HKQuantitySample]
    let oxygenSamples: [HKQuantitySample]
    let ecgSamples: [HKElectrocardiogram]

    // MARK: State
    @State private var showNoDataAlert = false
    @State private var includeFullData = false

    // MARK: Formatters
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    private let timeFormatter: DateFormatter = {
        let tf = DateFormatter()
        tf.timeStyle = .short
        return tf
    }()

    // MARK: Computed Properties
    private func filter<T>(_ all: [T], key: KeyPath<T, Date>) -> [T] {
        all.filter { Calendar.current.isDate($0[keyPath: key], inSameDayAs: date) }
    }
    private var hrPoints: [DayPoint] {
        filter(hrSamples, key: \ .startDate).map { DayPoint(time: $0.startDate,
            value: $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))) }
    }
    private var restPoints: [DayPoint] {
        filter(restingSamples, key: \ .startDate).map { DayPoint(time: $0.startDate,
            value: $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))) }
    }
    private var oxyPoints: [DayPoint] {
        filter(oxygenSamples, key: \ .startDate).map { DayPoint(time: $0.startDate,
            value: $0.quantity.doubleValue(for: HKUnit.percent()) * 100) }
    }
    private var latestECG: HKElectrocardiogram? {
        ecgSamples.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }.last
    }
    private func stats(_ values: [Double]) -> (avg: Int, min: Int, max: Int) {
        guard !values.isEmpty else { return (0, 0, 0) }
        let avg = Int(values.reduce(0, +) / Double(values.count))
        return (avg, Int(values.min()!), Int(values.max()!))
    }

    // MARK: View
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Health Data for \(dateFormatter.string(from: date))")
                    .font(.headline)
                    .padding(.horizontal)

                // Averages Section
                VStack(alignment: .leading, spacing: 12) {
                    let (hrAvg, hrMin, hrMax) = stats(hrPoints.map { $0.value })
                    SummaryRow(label: "Heart Rate", avg: hrAvg, min: hrMin, max: hrMax,
                               unit: "BPM", color: .red)
                    let (rAvg, rMin, rMax) = stats(restPoints.map { $0.value })
                    SummaryRow(label: "Resting HR", avg: rAvg, min: rMin, max: rMax,
                               unit: "BPM", color: .blue)
                    let (oAvg, oMin, oMax) = stats(oxyPoints.map { $0.value })
                    SummaryRow(label: "Oxygen Sat", avg: oAvg, min: oMin, max: oMax,
                               unit: "%", color: .teal)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)

                // Latest ECG Section - Significantly increased height
                if let ecg = latestECG {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Latest ECG (\(timeFormatter.string(from: ecg.startDate)))")
                            .font(.subheadline)
                        
                        // Increased height significantly to show full ECG
                        ECGCard(ecg: ecg)
                            .frame(height: 240) // Increased from 120 to 200
                            .padding(.vertical, 4) // Small padding within container
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    .padding(.horizontal)
                    .padding(.bottom, 16) // Increased bottom padding for separation
                }

                // Full Data Toggle & Share Button
                VStack(spacing: 16) { // Increased spacing between toggle and button
                    Toggle("Include Full Data", isOn: $includeFullData)
                        .padding(.horizontal, 4)
                    
                    Button(action: exportAndShare) {
                        Label("Share CSV", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10) // Slightly larger touch target
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                .padding(.horizontal)
                .alert("No Data to Export", isPresented: $showNoDataAlert) {
                    Button("OK", role: .cancel) {}
                }

                Spacer(minLength: 30) // Increased minimum spacing at bottom
            }
            .padding(.vertical)
        }
    }

    /// Export summary or full data including ECG waveform via callback query
    private func exportAndShare() {
        guard !(hrPoints.isEmpty && restPoints.isEmpty && oxyPoints.isEmpty) else {
            showNoDataAlert = true
            return
        }
        var csv = "Metric,Time,Value\n"
        // Summary
        let (hrAvg, hrMin, hrMax) = stats(hrPoints.map { $0.value })
        csv += "HeartRate,Average,\(hrAvg)\n"
        csv += "HeartRate,Min,\(hrMin)\n"
        csv += "HeartRate,Max,\(hrMax)\n"
        let (rAvg, rMin, rMax) = stats(restPoints.map { $0.value })
        csv += "RestingHR,Average,\(rAvg)\n"
        csv += "RestingHR,Min,\(rMin)\n"
        csv += "RestingHR,Max,\(rMax)\n"
        let (oAvg, oMin, oMax) = stats(oxyPoints.map { $0.value })
        csv += "OxygenSat,Average,\(oAvg)\n"
        csv += "OxygenSat,Min,\(oMin)\n"
        csv += "OxygenSat,Max,\(oMax)\n"
        if let ecg = latestECG {
            csv += "ECG,\(timeFormatter.string(from: ecg.startDate)),\(ecg.classification)\n"
        }

        if includeFullData, let ecg = latestECG {
            // Append full series
            csv += "\nFull Data\n"
            hrPoints.forEach { pt in
                csv += "HeartRate,\(timeFormatter.string(from: pt.time)),\(pt.value)\n"
            }
            restPoints.forEach { pt in
                csv += "RestingHR,\(timeFormatter.string(from: pt.time)),\(pt.value)\n"
            }
            oxyPoints.forEach { pt in
                csv += "OxygenSat,\(timeFormatter.string(from: pt.time)),\(pt.value)\n"
            }
            // ECG waveform export via HKElectrocardiogramQuery
            csv += "\nECGVoltage (sec,mV)\n"
            let store = HKHealthStore()
            var voltageLines: [String] = []
            let sem = DispatchSemaphore(value: 0)
            let query = HKElectrocardiogramQuery(ecg) { _, result in
                switch result {
                case .measurement(let m):
                    if let q = m.quantity(for: .appleWatchSimilarToLeadI) {
                        let mv = q.doubleValue(for: HKUnit.volt()) * 1000
                        let seconds = m.timeSinceSampleStart
                        voltageLines.append("\(String(format: "%.3f", seconds)),\(String(format: "%.3f", mv))")
                    }
                case .done:
                    sem.signal()
                case .error:
                    sem.signal()
                }
            }
            store.execute(query)
            sem.wait()
            voltageLines.forEach { line in
                csv += "ECGVoltage,\(line)\n"
            }
        }

        // Write CSV & share
        let filename = "HealthData-\(Int(date.timeIntervalSince1970)).csv"
        let url = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = UIApplication.shared.windows.first
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(vc, animated: true)
            }
        } catch {
            showNoDataAlert = true
        }
    }
}

/// A simple reusable row for avg/min/max
private struct SummaryRow: View {
    let label: String, avg: Int, min: Int, max: Int, unit: String, color: Color
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(color)
                .font(.subheadline)
            Spacer()
            Text("avg: \(avg) \(unit)   min: \(min)   max: \(max)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
