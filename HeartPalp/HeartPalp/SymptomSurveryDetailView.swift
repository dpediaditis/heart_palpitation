//
//  OxygenDetailView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 21/4/25.
//

// OxygenDetailView.swift
import SwiftUI
import HealthKit

struct SymptomSurveyDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private var latestSurvey: (authored: String, answers: [String])? {
        guard let jsonString = UserDefaults.standard.string(forKey: "latestSymptomSurveyResponse"),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let authored = json["authored"] as? String,
              let items = json["item"] as? [[String: Any]] else {
            return nil
        }
        var answers: [String] = []
        for item in items {
            if let text = item["text"] as? String {
                if let answerArr = item["answer"] as? [[String: Any]], let answer = answerArr.first {
                    if let value = answer["valueString"] as? String {
                        answers.append("\(text): \(value)")
                    } else if let value = answer["valueInteger"] {
                        answers.append("\(text): \(value)")
                    } else if let value = answer["valueBoolean"] {
                        answers.append("\(text): \(value)")
                    } else if let value = answer["valueCoding"] as? [String: Any], let display = value["display"] as? String {
                        answers.append("\(text): \(display)")
                    }
                } else {
                    answers.append(text)
                }
            }
        }
        return (authored, answers)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let survey = latestSurvey {
                        Text("Symptom Survey Details")
                            .font(.headline)
                        Text("Authored: \(survey.authored)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        ForEach(survey.answers, id: \.self) { answer in
                            detailRow(label: answer)
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

    @ViewBuilder
    private func detailRow(label: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
