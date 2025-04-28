//import SwiftUI
//import SpeziQuestionnaire
//import ModelsR4
//
//
//struct MyQuestionnaireScreen: View {
//    @State private var showQuestionnaire = false
//    @State private var questionnaire: Questionnaire? = nil
//
//    var body: some View {
//        VStack {
//            if let questionnaire {
//                Button("Start Questionnaire") {
//                    showQuestionnaire = true
//                }
//                .sheet(isPresented: $showQuestionnaire) {
//                    QuestionnaireView(
//                        questionnaire: questionnaire,
//                        completionStepMessage: "Thank you for completing the survey!",
//                        questionnaireResult: handleQuestionnaireResult
//                    )
//                }
//            } else {
//                ProgressView("Loading Questionnaire...")
//                    .onAppear {
//                        loadQuestionnaire()
//                    }
//            }
//        }
//    }
//
//    private func loadQuestionnaire() {
//        guard let url = Bundle.main.url(forResource: "sample-questionnaire", withExtension: "json"),
//              let data = try? Data(contentsOf: url) else {
//            print("Failed to load sample-questionnaire.json")
//            return
//        }
//
//        do {
//            let decoder = JSONDecoder()
//            let loadedQuestionnaire = try decoder.decode(Questionnaire.self, from: data)
//            questionnaire = loadedQuestionnaire
//        } catch {
//            print("Failed to decode sample-questionnaire.json: \(error)")
//        }
//    }
//
//    @MainActor
//    private func handleQuestionnaireResult(_ result: QuestionnaireResult) async {
//        switch result {
//        case let .completed(response):
//            print("Questionnaire completed! Response: \(response)")
//            // You can save the response here (e.g., Firebase)
//        case .cancelled:
//            print("User cancelled the questionnaire.")
//        case .failed:
//            print("Questionnaire failed.")
//        }
//    }
//}
//
//
//#Preview {
//    TestQuestionnaireScreen()
//
//}
