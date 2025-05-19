import SwiftUI

struct SymptomSurveyView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @StateObject private var fhirService = FHIRDataService()
    @Binding var shouldIncludePartOf: Bool
    
    init(isPresented: Binding<Bool>, shouldIncludePartOf: Binding<Bool>) {
        self._isPresented = isPresented
        self._shouldIncludePartOf = shouldIncludePartOf
        print("📱 SymptomSurveyView: Initialized with shouldIncludePartOf = \(shouldIncludePartOf.wrappedValue)")
    }
    
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
            CustomQuestionnaireView(
                questionnaire: questionnaire,
                onComplete: { response in
                    print("✅ Questionnaire completed with response")
                    
                    // Print the response for debugging
                    if let jsonData = try? JSONSerialization.data(withJSONObject: response.toDictionary(), options: [.prettyPrinted, .sortedKeys]),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print("\n📋 Final JSON for FHIR server:")
                        print("----------------------------------------")
                        print(jsonString)
                        print("----------------------------------------\n")
                    }
                    
                    // Send to FHIR server
                    Task {
                        do {
                            try await fhirService.uploadQuestionnaireResponse(response.toDictionary())
                            print("✅ Successfully sent questionnaire response to FHIR server")
                        } catch {
                            print("❌ Failed to send questionnaire response to FHIR server: \(error)")
                        }
                    }
                    
                    isPresented = false
                },
                onCancel: {
                    print("ℹ️ Questionnaire cancelled")
                    isPresented = false
                },
                shouldIncludePartOf: $shouldIncludePartOf
            )
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


