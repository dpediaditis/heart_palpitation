// HeartRateSimpleDetailView.swift
import SwiftUI
import HealthKit

struct HeartRateSimpleDetailView: View {
    let title: String
    let color: Color
    let samples: [HKQuantitySample]  // ← actual data

    @Environment(\.dismiss) private var dismiss

    // Compute BPM values from the samples
    private var bpmValues: [Double] {
        samples.map {
            $0.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        }
    }

    private var average: Int {
        guard !bpmValues.isEmpty else { return 0 }
        return Int(bpmValues.reduce(0, +) / Double(bpmValues.count))
    }

    private var maximum: Int {
        Int(bpmValues.max() ?? 0)
    }

    private var minimum: Int {
        Int(bpmValues.min() ?? 0)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Main info section with real stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(title) Details")
                            .font(.headline)
                            .foregroundColor(color)

                        detailRow(label: "Today's Average", value: "\(average) BPM")
                        detailRow(label: "Maximum", value: "\(maximum) BPM")
                        detailRow(label: "Minimum", value: "\(minimum) BPM")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                    // Heart rate zones (static)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Heart Rate Zones")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Low: Below 60 BPM")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Text("• Normal: 60–100 BPM")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Text("• Elevated: 100–120 BPM")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                            Text("• High: Above 120 BPM")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                    // Health tip (static)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health Tip")
                            .font(.headline)
                        Text("Regular exercise can help lower your resting heart rate over time.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
