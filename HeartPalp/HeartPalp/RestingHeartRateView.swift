//
//  RestingHeartRateView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 21/4/25.
//

// RestingHeartRateDetailView.swift
import SwiftUI
import HealthKit

struct RestingHeartRateDetailView: View {
    let title: String
    let color: Color
    let samples: [HKQuantitySample]
    @Environment(\.dismiss) private var dismiss

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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(title) Details")
                            .font(.headline)
                            .foregroundColor(color)

                        detailRow(label: "Today's Average", value: "\(average) BPM")
                        detailRow(label: "Maximum", value: "\(maximum) BPM")
                        detailRow(label: "Minimum", value: "\(minimum) BPM")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                    // (You can add additional resting‑HR‑specific content here)
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
