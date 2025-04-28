import SwiftUI
import HealthKit
import SpeziHealthKit
import SpeziHealthKitUI

struct ActivityRingCard: View {
    // MARK: — HealthKit queries
    @HealthKitQuery(.stepCount, timeRange: .today) private var steps
    @HealthKitQuery(.activeEnergyBurned, timeRange: .today) private var energy
    @HealthKitQuery(.appleExerciseTime, timeRange: .today) private var exercise
    @HealthKitQuery(.appleStandTime, timeRange: .today) private var stand

    // MARK: — UI state
    @State private var showDetail = false

    // MARK: — Computed totals
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

    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("Activity Rings", systemImage: "figure.walk.circle")
                    .font(.headline)
                HStack(spacing: 16) {
                    ringView(value: totalSteps, label: "Steps")
                    ringView(value: totalEnergy, label: "Energy", unit: "kcal")
                    ringView(value: totalExercise, label: "Exercise", unit: "min")
                    ringView(value: totalStand, label: "Stand", unit: "min")
                }
                .frame(height: 60)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            NavigationView {
                ActivityDetailView(
                    steps: Array(steps),
                    energy: Array(energy),
                    exercise: Array(exercise),
                    stand: Array(stand)
                )
                .navigationTitle("Activity Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showDetail = false
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ringView(value: Int, label: String, unit: String = "") -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ActivityDetailView: View {
    let steps: [HKQuantitySample]
    let energy: [HKQuantitySample]
    let exercise: [HKQuantitySample]
    let stand: [HKQuantitySample]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                detailSection(
                    title: "Steps",
                    samples: steps,
                    unit: .count(),
                    unitLabel: "steps"
                )
                detailSection(
                    title: "Energy Burned",
                    samples: energy,
                    unit: .kilocalorie(),
                    unitLabel: "kcal"
                )
                detailSection(
                    title: "Exercise Time",
                    samples: exercise,
                    unit: .minute(),
                    unitLabel: "min"
                )
                detailSection(
                    title: "Stand Time",
                    samples: stand,
                    unit: .minute(),
                    unitLabel: "min"
                )
            }
            .padding()
        }
    }

    @ViewBuilder
    private func detailSection(
        title: String,
        samples: [HKQuantitySample],
        unit: HKUnit,
        unitLabel: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if samples.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(Array(samples.prefix(10)), id: \.uuid) { sample in
                    HStack {
                        Text(sample.startDate, style: .time)
                            .font(.caption)
                        Spacer()
                        Text("\(Int(sample.quantity.doubleValue(for: unit))) \(unitLabel)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
    }
}


