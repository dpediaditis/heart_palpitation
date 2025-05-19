import SwiftUI

struct SymptomSurveyDetailViewNew: View {
    let summary: DashboardView.SymptomSurveySummary?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let summary = summary {
                        Text("Latest Symptom Survey Details")
                            .font(.headline)
                            .foregroundColor(.teal)
                        Text("Authored: \(summary.authored)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ForEach(summary.answers, id: \.self) { answer  in
                            Text(answer)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    } else {
                        Text("No symptom survey data available.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Symptom Survey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
} 
