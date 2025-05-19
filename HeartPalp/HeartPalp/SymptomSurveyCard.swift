import SwiftUI

struct SymptomSurveyCard: View {
    let summary: DashboardView.SymptomSurveySummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "heart.text.square")
                    .foregroundColor(.teal)
                Text("Symptom Survey")
                    .font(.headline)
            if let summary = summary {
                Text("Authored: \(summary.authored)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text("Tap for details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No survey data")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.teal.opacity(0.1))
        .cornerRadius(12)
    }
} 
