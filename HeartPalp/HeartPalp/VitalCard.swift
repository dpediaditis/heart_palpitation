import SwiftUI
import HealthKit
import SpeziHealthKit
import SpeziHealthKitUI


struct VitalCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let samples: [HKQuantitySample]?
    
    @State private var showDetail = false
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        samples: [HKQuantitySample]? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.samples = samples
    }
    
    var body: some View {
        Button {
            if samples != nil {
                showDetail = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label { Text(title).font(.headline) }
                icon: { Image(systemName: icon).foregroundColor(color) }
                Text(value).font(.title).bold()
                if samples != nil {
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
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            Group {
                if title == "Current Heart Rate" {
                    HeartRateSimpleDetailView(
                        title: title,
                        color: color,
                        samples: samples ?? []
                    )
                } else if title == "Resting HR" {
                    RestingHeartRateDetailView(
                        title: title,
                        color: color,
                        samples: samples ?? []
                    )
                } else if title == "Oxygen Saturation" {
                    OxygenDetailView(
                        title: title,
                        color: color,
                        samples: samples ?? []
                    )
                } else {
                    // fallback: simple view with its own dismiss
                    NavigationView {
                        VStack(spacing: 16) {
                            Text("No details available")
                                .font(.headline)
                            Text("There’s no data to display for “\(title)”.")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close") { showDetail = false }
                            }
                        }
                    }
                }
            }
        }
    }
}
