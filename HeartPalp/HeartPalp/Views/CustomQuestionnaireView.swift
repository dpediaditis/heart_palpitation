import SwiftUI

struct CustomQuestionnaireView: View {
    let questionnaire: Questionnaire
    let onComplete: (QuestionnaireResponse) -> Void
    let onCancel: () -> Void
    
    @State private var answers: [String: Any] = [:]
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            // Progress indicator
            ProgressView(value: Double(currentPage), total: Double(questionnaire.item.count))
                .padding()
            
            // Question content
            if currentPage < questionnaire.item.count {
                let currentItem = questionnaire.item[currentPage]
                QuestionView(
                    item: currentItem,
                    selectedAnswer: Binding(
                        get: { 
                            print("🔍 Getting answer for \(currentItem.linkId)")
                            if currentItem.type == "open-choice" && currentItem.extensions?.contains(where: { $0.valueCodeableConcept.coding.contains(where: { $0.code == "check-box" }) }) == true {
                                print("📦 This is a checkbox question")
                                if let existingValue = answers[currentItem.linkId] as? [Coding] {
                                    let displays = existingValue.map { $0.display }
                                    print("📦 Found existing selections: \(displays)")
                                    return existingValue
                                }
                                print("📦 No existing selections, initializing empty array")
                                answers[currentItem.linkId] = []
                                return []
                            }
                            let value = answers[currentItem.linkId]
                            print("📦 Returning value: \(String(describing: value))")
                            return value
                        },
                        set: { 
                            print("📝 Setting answer for \(currentItem.linkId) to: \(String(describing: $0))")
                            answers[currentItem.linkId] = $0 
                        }
                    ),
                    onChoiceSelected: { coding in
                        print("🎯 Single choice selected: \(coding.display)")
                        answers[currentItem.linkId] = coding
                    },
                    onMultiChoiceSelected: { coding in
                        print("🎯 Multi-choice selection attempt for: \(coding.display)")
                        var currentSelections = answers[currentItem.linkId] as? [Coding] ?? []
                        let beforeDisplays = currentSelections.map { $0.display }
                        print("📦 Current selections before update: \(beforeDisplays)")
                        
                        if let index = currentSelections.firstIndex(where: { $0.id == coding.id }) {
                            print("🗑️ Removing selection at index \(index)")
                            currentSelections.remove(at: index)
                        } else {
                            print("➕ Adding new selection")
                            currentSelections.append(coding)
                        }
                        
                        let afterDisplays = currentSelections.map { $0.display }
                        print("📦 Updated selections: \(afterDisplays)")
                        withAnimation {
                            answers[currentItem.linkId] = currentSelections
                        }
                    }
                )
                .padding()
            }
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                
                Spacer()
                
                if currentPage < questionnaire.item.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                } else {
                    Button("Submit") {
                        submitQuestionnaire()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(questionnaire.title)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private func submitQuestionnaire() {
        print("\n📝 Submitting questionnaire with answers:")
        for (linkId, value) in answers {
            if let codings = value as? [Coding] {
                let displays = codings.map { $0.display }
                print("- \(linkId): Multiple selections - \(displays)")
            } else {
                print("- \(linkId): \(value)")
            }
        }
        
        let response = createResponse()
        onComplete(response)
    }
    
    private func createResponse() -> QuestionnaireResponse {
        let responseItems = questionnaire.item.map { item in
            createResponseItem(from: item)
        }
        
        return QuestionnaireResponse(
            authored: ISO8601DateFormatter().string(from: Date()),
            item: responseItems
        )
    }
    
    private func createResponseItem(from item: QuestionnaireItem) -> QuestionnaireResponse.ResponseItem {
        let answers = createAnswers(for: item)
        let nestedItems = item.item?.map { createResponseItem(from: $0) }
        
        return QuestionnaireResponse.ResponseItem(
            linkId: item.linkId,
            text: item.text,
            answer: answers,
            item: nestedItems
        )
    }
    
    private func createAnswers(for item: QuestionnaireItem) -> [QuestionnaireResponse.Answer] {
        let value = answers[item.linkId]
        print("\n📦 Creating answer for item \(item.linkId)")
        print("📦 Raw value: \(String(describing: value))")
        
        switch item.type {
        case "string":
            if let stringValue = value as? String {
                print("📦 Creating string answer: \(stringValue)")
                return [QuestionnaireResponse.Answer(
                    valueString: stringValue,
                    valueInteger: nil,
                    valueBoolean: nil,
                    valueDateTime: nil,
                    valueCoding: nil
                )]
            }
        case "integer":
            if let intValue = value as? Int {
                print("📦 Creating integer answer: \(intValue)")
                return [QuestionnaireResponse.Answer(
                    valueString: nil,
                    valueInteger: intValue,
                    valueBoolean: nil,
                    valueDateTime: nil,
                    valueCoding: nil
                )]
            }
        case "boolean":
            if let boolValue = value as? Bool {
                print("📦 Creating boolean answer: \(boolValue)")
                return [QuestionnaireResponse.Answer(
                    valueString: nil,
                    valueInteger: nil,
                    valueBoolean: boolValue,
                    valueDateTime: nil,
                    valueCoding: nil
                )]
            }
        case "dateTime":
            if let dateValue = value as? String {
                print("📦 Creating dateTime answer: \(dateValue)")
                return [QuestionnaireResponse.Answer(
                    valueString: nil,
                    valueInteger: nil,
                    valueBoolean: nil,
                    valueDateTime: dateValue,
                    valueCoding: nil
                )]
            }
        case "choice", "open-choice":
            if let codings = value as? [Coding] {
                print("📦 Creating multiple answers for \(item.linkId):")
                let displays = codings.map { $0.display }
                displays.forEach { display in
                    print("  - \(display)")
                }
                return codings.map { coding in
                    QuestionnaireResponse.Answer(
                        valueString: nil,
                        valueInteger: nil,
                        valueBoolean: nil,
                        valueDateTime: nil,
                        valueCoding: coding
                    )
                }
            } else if let coding = value as? Coding {
                print("📦 Creating single coding answer: \(coding.display)")
                return [QuestionnaireResponse.Answer(
                    valueString: nil,
                    valueInteger: nil,
                    valueBoolean: nil,
                    valueDateTime: nil,
                    valueCoding: coding
                )]
            }
        default:
            break
        }
        return []
    }
}

struct QuestionView: View {
    let item: QuestionnaireItem
    @Binding var selectedAnswer: Any?
    let onChoiceSelected: (Coding) -> Void
    let onMultiChoiceSelected: (Coding) -> Void
    
    private var isCheckboxQuestion: Bool {
        guard let extensions = item.extensions else { return false }
        return extensions.contains { ext in
            let coding = ext.valueCodeableConcept.coding
            return coding.contains { $0.code == "check-box" }
        }
    }
    
    private var selectedCodings: [Coding]? {
        return selectedAnswer as? [Coding]
    }
    
    private var selectedCoding: Coding? {
        return selectedAnswer as? Coding
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(item.text)
                .font(.headline)
            
            switch item.type {
            case "string":
                TextField("Enter your answer", text: Binding(
                    get: { selectedAnswer as? String ?? "" },
                    set: { selectedAnswer = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            case "integer":
                if let value = selectedAnswer as? Int {
                    Stepper("\(value)", value: Binding(
                        get: { value },
                        set: { selectedAnswer = $0 }
                    ))
                } else {
                    TextField("Enter a number", text: Binding(
                        get: { selectedAnswer as? String ?? "" },
                        set: { selectedAnswer = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                }
                
            case "boolean":
                Toggle("Yes/No", isOn: Binding(
                    get: { selectedAnswer as? Bool ?? false },
                    set: { selectedAnswer = $0 }
                ))
                
            case "choice", "open-choice":
                if let options = item.answerOption {
                    if isCheckboxQuestion {
                        // Multiple choice with checkboxes
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(options, id: \.valueCoding.id) { option in
                                let isSelected = selectedCodings?.contains(where: { $0.id == option.valueCoding.id }) ?? false
                                Button(action: {
                                    onMultiChoiceSelected(option.valueCoding)
                                }) {
                                    HStack {
                                        Text(option.valueCoding.display)
                                        Spacer()
                                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                            .foregroundColor(isSelected ? .blue : .gray)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 4)
                            }
                        }
                    } else {
                        // Single choice
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(options, id: \.valueCoding.id) { option in
                                let isSelected = selectedCoding?.id == option.valueCoding.id
                                Button(action: {
                                    onChoiceSelected(option.valueCoding)
                                }) {
                                    HStack {
                                        Text(option.valueCoding.display)
                                        Spacer()
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isSelected ? .blue : .gray)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
            default:
                Text("Unsupported question type: \(item.type)")
                    .foregroundColor(.red)
            }
        }
    }
} 