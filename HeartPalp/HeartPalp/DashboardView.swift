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
    @HealthKitQuery(.bloodOxygen, timeRange: .today) private var oxygen
    @HealthKitQuery(.electrocardiogram, timeRange: .currentYear) private var ecgSamples

    @StateObject private var fhirService = FHIRDataService()

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

    // MARK: – Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Vital cards
                    VitalCard(
                        title: "Current Heart Rate",
                        value: latestHR,
                        icon: "heart.fill",
                        color: .red,
                        samples: Array(hrTodaySamples)
                    )
                    HStack(spacing: 16) {
                        VitalCard(
                            title: "Resting HR",
                            value: latestResting,
                            icon: "bed.double.fill",
                            color: .blue,
                            samples: Array(restingHR)
                        )
                        VitalCard(
                            title: "Oxygen Saturation",
                            value: latestO2,
                            icon: "lungs.fill",
                            color: .teal,
                            samples: Array(oxygen)
                        )
                    }

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
                .navigationTitle("Health Dashboard")
                .onAppear {
                                    Task {
                                        do {
                                            try await fhirService.uploadAllHealthData(
                                                hrSamples: Array(hrTodaySamples),
                                                restingSamples: Array(restingHR),
                                                oxygenSamples: Array(oxygen)
                                            )
                                            print("✅ Auto-upload completed")
                                        } catch {
                                            print("❌ Auto-upload failed: \(error)")
                                        }
                                    }
                                }
            }
        }
    }
}
