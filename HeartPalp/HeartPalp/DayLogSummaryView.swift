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
    let stepSamples:     [HKQuantitySample]
    let energySamples:   [HKQuantitySample]
    let exerciseSamples: [HKQuantitySample]
    let standSamples:    [HKQuantitySample]
    let glucoseSamples:  [HKQuantitySample]
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
    private func makePoints(
        from samples: [HKQuantitySample],
        unit: HKUnit
    ) -> [DayPoint] {
        filter(samples, key: \.startDate).map {
            DayPoint(
                time: $0.startDate,
                value: $0.quantity.doubleValue(for: unit)
            )
        }
    }
    private var stepPoints:     [DayPoint] { makePoints(from: stepSamples,     unit: HKUnit.count()) }
    private var energyPoints:   [DayPoint] { makePoints(from: energySamples,   unit: HKUnit.kilocalorie()) }
    private var exercisePoints: [DayPoint] { makePoints(from: exerciseSamples, unit: HKUnit.minute()) }
    private var standPoints:    [DayPoint] { makePoints(from: standSamples,    unit: HKUnit.minute()) }
    
    private var glucosePoints: [DayPoint] {
        // first get mmol/L
        let mmolPerLUnit = HKUnit
            .moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
            .unitDivided(by: .liter())
        return filter(glucoseSamples, key: \.startDate).map {
            let mmol = $0.quantity.doubleValue(for: mmolPerLUnit)
            let mgdl = mmol * 18.0
            return DayPoint(time: $0.startDate, value: mgdl)
        }
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
                // 3) Activity summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity")
                        .font(.subheadline)
                    ActivitySummaryView(
                        stepPoints:     stepPoints,
                        energyPoints:   energyPoints,
                        exercisePoints: exercisePoints,
                        standPoints:    standPoints
                    )
                }
                .padding()
                .frame(maxWidth: .infinity)
                
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6)))
                .padding(.horizontal)
                
                // 4) Glucose summary
                let (gAvg, gMin, gMax) = stats(glucosePoints.map(\.value))
                VStack(alignment: .leading, spacing: 12) {
                    SummaryRow(
                        label:     "Glucose",
                        avg:        gAvg,
                        min:        gMin,
                        max:        gMax,
                        unit:     "mg/dL",
                        color:     .purple
                    )
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6)))
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
    
    private func exportAndShare() {
        // 1) Make sure there’s something to export
        guard !(hrPoints.isEmpty
                && restPoints.isEmpty
                && oxyPoints.isEmpty
                && stepPoints.isEmpty
                && energyPoints.isEmpty
                && exercisePoints.isEmpty
                && standPoints.isEmpty
                && glucosePoints.isEmpty) else {
            showNoDataAlert = true
            return
        }
        
        // 2) Build the header
        var csv = "Metric,Type,Time,Value\n"
        
        // 3) Summaries for vitals
        let (hrAvg, hrMin, hrMax) = stats(hrPoints.map(\.value))
        csv += "HeartRate,Average,,\(hrAvg)\n"
        csv += "HeartRate,Min,,\(hrMin)\n"
        csv += "HeartRate,Max,,\(hrMax)\n"
        
        let (rAvg, rMin, rMax) = stats(restPoints.map(\.value))
        csv += "RestingHR,Average,,\(rAvg)\n"
        csv += "RestingHR,Min,,\(rMin)\n"
        csv += "RestingHR,Max,,\(rMax)\n"
        
        let (oAvg, oMin, oMax) = stats(oxyPoints.map(\.value))
        csv += "OxygenSat,Average,,\(oAvg)\n"
        csv += "OxygenSat,Min,,\(oMin)\n"
        csv += "OxygenSat,Max,,\(oMax)\n"
        
        // 4) Summaries for activity (these are totals)
        let totalSteps   = stepPoints.reduce(0) { $0 + Int($1.value) }
        let totalEnergy  = energyPoints.reduce(0) { $0 + Int($1.value) }
        let totalExercise = exercisePoints.reduce(0) { $0 + Int($1.value) }
        let totalStand   = standPoints.reduce(0) { $0 + Int($1.value) }
        
        csv += "Steps,Total,,\(totalSteps)\n"
        csv += "Energy,Total,,\(totalEnergy)\n"
        csv += "Exercise,Total,,\(totalExercise)\n"
        csv += "Stand,Total,,\(totalStand)\n"
        
        // 5) Summary for glucose (avg/min/max mg/dL)
        let (gAvg, gMin, gMax) = stats(glucosePoints.map(\.value))
        csv += "Glucose,Average,,\(gAvg)\n"
        csv += "Glucose,Min,,\(gMin)\n"
        csv += "Glucose,Max,,\(gMax)\n"
        
        // 6) ECG classification (if any)
        if let ecg = latestECG {
            csv += "ECG,Classification,\(timeFormatter.string(from: ecg.startDate)),\(ecg.classification.rawValue)\n"
        }
        
        // 7) If the user wants full data, append every timestamp/value
        if includeFullData {
            csv += "\nFull Data\n"
            func appendPoints(_ points: [DayPoint], metric: String) {
                points.forEach {
                    csv += "\(metric),Sample,\(timeFormatter.string(from: $0.time)),\($0.value)\n"
                }
            }
            
            appendPoints(hrPoints,      metric: "HeartRate")
            appendPoints(restPoints,    metric: "RestingHR")
            appendPoints(oxyPoints,     metric: "OxygenSat")
            appendPoints(stepPoints,    metric: "Steps")
            appendPoints(energyPoints,  metric: "Energy")
            appendPoints(exercisePoints,metric: "Exercise")
            appendPoints(standPoints,   metric: "Stand")
            appendPoints(glucosePoints, metric: "Glucose")
            
            // And ECG waveform volts/sec as before
            let store = HKHealthStore()
            var voltageLines: [String] = []
            let sem = DispatchSemaphore(value: 0)
            if let ecg = latestECG {
                let query = HKElectrocardiogramQuery(ecg) { _, result in
                    switch result {
                    case .measurement(let m):
                        if let q = m.quantity(for: .appleWatchSimilarToLeadI) {
                            let mv = q.doubleValue(for: HKUnit.volt()) * 1000
                            let seconds = m.timeSinceSampleStart
                            voltageLines.append("\(seconds),\(mv)")
                        }
                    case .done, .error:
                        sem.signal()
                    }
                }
                store.execute(query)
                sem.wait()
                voltageLines.forEach {
                    csv += "ECGVoltage,Sample,\($0)\n"
                }
            }
        }
        
        // 8) Write & share
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
/// Renders the four activity totals in a horizontal stack
private struct ActivitySummaryView: View {
    let stepPoints: [DayPoint]
    let energyPoints: [DayPoint]
    let exercisePoints: [DayPoint]
    let standPoints: [DayPoint]

    private var totalSteps: Int {
        Int(stepPoints.reduce(0) { $0 + $1.value })
    }
    private var totalEnergy: Int {
        Int(energyPoints.reduce(0) { $0 + $1.value })
    }
    private var totalExercise: Int {
        Int(exercisePoints.reduce(0) { $0 + $1.value })
    }
    private var totalStand: Int {
        Int(standPoints.reduce(0) { $0 + $1.value })
    }

    var body: some View {
        HStack(spacing: 16) {
            SmallMetricView(value: totalSteps,   label: "Steps")
            Spacer()
            SmallMetricView(value: totalEnergy,  label: "Energy", unit: "kcal")
            Spacer()

            SmallMetricView(value: totalExercise,label: "Exercise", unit: "min")
            Spacer()

            SmallMetricView(value: totalStand,   label: "Stand",    unit: "min")
            Spacer()

        }
        .frame(maxWidth: .infinity)
    }

    private struct SmallMetricView: View {
        let value: Int, label: String, unit: String?

        init(value: Int, label: String, unit: String? = nil) {
            self.value = value; self.label = label; self.unit = unit
        }

        var body: some View {
            VStack(spacing: 4) {
                Text("\(value)")
                    .font(.headline)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let u = unit {
                    Text(u)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
