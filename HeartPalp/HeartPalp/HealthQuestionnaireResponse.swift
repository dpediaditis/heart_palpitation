//
//  HealthQuestionnaireResponse.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 4/5/25.
//

import Foundation

/// Holds the user’s answers and can emit a FHIR QuestionnaireResponse JSON blob.
struct HealthQuestionnaireResponse {
    var age: Int?
    var gender: Gender = .unspecified
    var heightCm: Double?
    var weightKg: Double?
    var smoking: Bool = false
    var alcoholFrequency: AlcoholFrequency = .never
    var exerciseDaysPerWeek: Int = 0
    var sleepHours: Double = 7.0
    var stressLevel: Int = 5

    enum Gender: String, CaseIterable, Identifiable {
        case male, female, other, unspecified
        var id: String { rawValue }
        var display: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .other: return "Other"
            case .unspecified: return "Prefer not to say"
            }
        }
    }
    enum AlcoholFrequency: String, CaseIterable, Identifiable {
        case never, monthly, weekly, daily
        var id: String { rawValue }
        var display: String {
            switch self {
            case .never:   return "Never"
            case .monthly: return "Monthly or less"
            case .weekly:  return "Weekly"
            case .daily:   return "Daily or almost daily"
            }
        }
    }

    /// Builds a FHIR QuestionnaireResponse payload
    func fhirJSON(questionnaireUrl: String = "Questionnaire/basic-health-questionnaire") throws -> Data {
        var items: [[String: Any]] = []

        if let age = age {
            items.append([
                "linkId": "age",
                "answer": [["valueInteger": age]]
            ])
        }
        items.append([
            "linkId": "gender",
            "answer": [[
                "valueCoding": [
                    "system": "http://hl7.org/fhir/administrative-gender",
                    "code": gender.rawValue,
                    "display": gender.display
                ]
            ]]
        ])
        if let h = heightCm {
            items.append([
                "linkId": "height",
                "answer": [["valueDecimal": h]]
            ])
        }
        if let w = weightKg {
            items.append([
                "linkId": "weight",
                "answer": [["valueDecimal": w]]
            ])
        }
        items.append([
            "linkId": "smoking",
            "answer": [["valueBoolean": smoking]]
        ])
        items.append([
            "linkId": "alcohol",
            "answer": [[
                "valueCoding": [
                    "code": alcoholFrequency.rawValue,
                    "display": alcoholFrequency.display
                ]
            ]]
        ])
        items.append([
            "linkId": "exercise",
            "answer": [["valueInteger": exerciseDaysPerWeek]]
        ])
        items.append([
            "linkId": "sleep",
            "answer": [["valueDecimal": sleepHours]]
        ])
        items.append([
            "linkId": "stress",
            "answer": [["valueInteger": stressLevel]]
        ])

        let root: [String: Any] = [
            "resourceType": "QuestionnaireResponse",
            "questionnaire": questionnaireUrl,
            "status": "completed",
            "item": items
        ]
        return try JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        )
    }
}
