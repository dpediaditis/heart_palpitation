import SwiftUI
import HealthKit



struct LineChartView: View {
    let samples: [HKQuantitySample]

    var body: some View {
        GeometryReader { geo in
            // Build (time, bpm) array
            let pts = samples
                .map { (
                    t: $0.startDate.timeIntervalSinceReferenceDate,
                    b: $0.quantity.doubleValue(
                        for: .count().unitDivided(by: .minute())
                    )
                ) }
                .sorted { $0.t < $1.t }

            // Bounds
            let xs = pts.map(\.t), ys = pts.map(\.b)
            let minX = xs.first!, maxX = xs.last!
            let minY = ys.min()!, maxY = ys.max()!
            let xRange = maxX - minX, yRange = maxY - minY
            let chartWidth = geo.size.width - 40   // leave space for y‑labels
            let chartHeight = geo.size.height - 30 // leave space for x‑labels

            ZStack {
                // Grid: 3 horizontal lines at 0%, 50%, 100%
                ForEach([0.0, 0.5, 1.0], id: \.self) { frac in
                    Path { p in
                        let y = CGFloat(1 - frac) * chartHeight
                        p.move(to: CGPoint(x: 40, y: y))
                        p.addLine(to: CGPoint(x: 40 + chartWidth, y: y))
                    }
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                }

                // Y‑axis labels
                VStack {
                    Text("\(Int(maxY))")
                    Spacer()
                    Text("\(Int((minY + maxY)/2))")
                    Spacer()
                    Text("\(Int(minY))")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40)
                .offset(x: 0, y: 0)

                // Chart Path
                Path { path in
                    for (i, p) in pts.enumerated() {
                        let xPos = 40 + CGFloat((p.t - minX)/xRange) * chartWidth
                        let yPos = CGFloat(1 - (p.b - minY)/yRange) * chartHeight
                        let pt = CGPoint(x: xPos, y: yPos)
                        if i == 0 { path.move(to: pt) }
                        else    { path.addLine(to: pt) }
                    }
                }
                .stroke(Color.red, lineWidth: 2)

                // X‑axis labels
                HStack {
                    Text(Date(timeIntervalSinceReferenceDate: minX),
                         style: .date)
                    Spacer()
                    Text(Date(timeIntervalSinceReferenceDate: maxX),
                         style: .date)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(height: 30)
                .offset(x: 40, y: chartHeight)
            }
        }
    }
}


