//
//  OxygenDetailView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 21/4/25.
//

// OxygenDetailView.swift
import SwiftUI
import HealthKit

struct OxygenDetailView: View {
    let title: String
    let color: Color
    let samples: [HKQuantitySample]
    @Environment(\.dismiss) private var dismiss

    private var pctValues: [Double] {
        samples.map {
            $0.quantity.doubleValue(for: HKUnit.percent()) * 100
        }
    }

    private var average: Int {
        guard !pctValues.isEmpty else { return 0 }
        return Int(pctValues.reduce(0, +) / Double(pctValues.count))
    }

    private var maximum: Int {
        Int(pctValues.max() ?? 0)
    }

    private var minimum: Int {
        Int(pctValues.min() ?? 0)
    }


    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(title) Details")
                            .font(.headline)
                            .foregroundColor(color)

                        detailRow(label: "Today's Average", value: "\(average)%")
                        detailRow(label: "Maximum", value: "\(maximum)%")
                        detailRow(label: "Minimum", value: "\(minimum)%")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Oxygen Saturation Levels")
                            .font(.headline)
                        Text("Normal: 95–100%\nLow: &lt; 95%")
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
