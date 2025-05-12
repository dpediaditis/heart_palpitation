//
//  ContentView.swift
//  PatientSymptomNew
//
//  Created by HARSIMRAN KAUR on 2025-04-28.
//

import SwiftUI
import SpeziQuestionnaire
import ModelsR4

struct ContentView: View {
    var questionnaire: Questionnaire? {
        if let url = Bundle.main.url(forResource: "PatientSymptomQuestionnaire", withExtension: "json") {
            print("Found file at: \(url)")
            if let data = try? Data(contentsOf: url) {
                do {
                    let resource = try JSONDecoder().decode(Questionnaire.self, from: data)
                    print("Successfully decoded questionnaire")
                    return resource
                } catch {
                    print("Decoding error: \(error)")
                }
            } else {
                print("Failed to load data from file")
            }
        } else {
            print("File not found in bundle")
        }
        return nil
    }

    var body: some View {
        if let questionnaire = questionnaire {
            QuestionnaireView(
                questionnaire: questionnaire,
                questionnaireResult: { result in
                    // This closure is called when the questionnaire is completed
                    print("Questionnaire completed: \(result)")
                    // You can save, upload, or process the result here
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        } else {
            Text("Failed to load questionnaire.")
        }
    }
}
