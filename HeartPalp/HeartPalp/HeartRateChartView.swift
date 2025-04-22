import SwiftUI
import Charts
import HealthKit

struct HeartRateChartView: View {
    let samples: [HKQuantitySample]
    let range: DashboardView.Range

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(samples) { sample in
                    let bpm = sample.quantity
                        .doubleValue(for: .count().unitDivided(by: .minute()))
                    
                    // Smooth line + area + dots
                    AreaMark(
                        x: .value("Time", sample.startDate),
                        y: .value("BPM", bpm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.red.opacity(0.3), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Time", sample.startDate),
                        y: .value("BPM", bpm)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Time", sample.startDate),
                        y: .value("BPM", bpm)
                    )
                    .symbolSize(30)
                    .foregroundStyle(.red)
                }
            }
            // X‑axis grid & labels
            .chartXAxis {
                switch range {
                case .today:
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [5]))
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    }
                case .week:
                    AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [5]))
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                case .month:
                    AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [5]))
                        AxisValueLabel(format: .dateTime.day(.defaultDigits))
                    }
                case .year:
                    AxisMarks(values: .automatic(desiredCount: 12)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [5]))
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
            }


            // Y‑axis grid & labels
            .chartYAxis {
                let bpms = samples.map {
                    $0.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                }
                if let min = bpms.min(), let max = bpms.max() {
                    let mid = (min + max) / 2
                    AxisMarks(values: [max, mid, min]) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [5]))
                        AxisValueLabel()
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
