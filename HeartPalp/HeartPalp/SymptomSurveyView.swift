import SwiftUI
import SpeziQuestionnaire
//import SpeziFHIR
import SpeziHealthKit
import ModelsR4

struct SymptomSurveyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var questionnaireResponse: QuestionnaireResponse?
    @Binding var isPresented: Bool
    
    var questionnaire: Questionnaire? {
        do {
            guard let url = Bundle.main.url(forResource: "PatientSymptomQuestionnaire", withExtension: "json") else {
                print("❌ Could not find PatientSymptomQuestionnaire.json in bundle")
                return nil
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(Questionnaire.self, from: data)
        } catch {
            print("❌ Failed to load questionnaire: \(error)")
            return nil
        }
    }
    
    var body: some View {
        if let questionnaire = questionnaire {
            QuestionnaireView(questionnaire: questionnaire) { result in
                switch result {
                case .completed(let response):
                    print("✅ Questionnaire completed with response")
                    questionnaireResponse = response
                    print(response)
                    // Dismiss all views to return to dashboard
                    isPresented = false
                case .cancelled:
                    print("ℹ️ Questionnaire cancelled")
                    // Dismiss all views to return to dashboard
                    isPresented = false
                case .failed:
                    print("❌ Questionnaire failed")
                    // Dismiss all views to return to dashboard
                    isPresented = false
                }
            }
            .navigationTitle("Symptom Survey")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // Dismiss all views to return to dashboard
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        } else {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("Failed to load questionnaire")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Please try again later")
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Dismiss all views to return to dashboard
                    isPresented = false
                }) {
                    Text("Go Back")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
}


