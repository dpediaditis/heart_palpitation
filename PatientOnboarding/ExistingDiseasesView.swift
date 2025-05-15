//
//  ExistingDiseasesView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding
import ModelsR4

struct ExistingDiseasesView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @EnvironmentObject var patientModel: PatientModel
    @State private var selectedDiseases: Set<String> = []
    @State private var otherDisease: String = ""
    
    let diseases = [
        "Heart related disorders",
        "Lungs related disorders",
        "Diabetes",
        "Thyroid disorders",
        "Chronic kidney disease",
        "Sleep apnea"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Medical History")
                .font(.title)
                .padding(.bottom)
            
            Text("Do you have any existing diseases?")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(diseases, id: \.self) { disease in
                        Toggle(isOn: Binding(
                            get: { selectedDiseases.contains(disease) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDiseases.insert(disease)
                                } else {
                                    selectedDiseases.remove(disease)
                                }
                            }
                        )) {
                            Text(disease)
                        }
                        .toggleStyle(CheckboxToggleStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Other (please specify):")
                            .font(.subheadline)
                        TextField("Enter other condition", text: $otherDisease)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.top)
                }
                .padding(.vertical)
            }
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                Button("Next") {
                    saveConditions()
                    onboardingNavigationPath.nextStep()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
    }
    
    private func saveConditions() {
        var conditions: [Condition] = []
        
        // Add selected diseases
        for disease in selectedDiseases {
            let condition = createCondition(
                code: getICD10Code(for: disease),
                display: disease
            )
            conditions.append(condition)
        }
        
        // Add other disease if specified
        if !otherDisease.trimmingCharacters(in: .whitespaces).isEmpty {
            let condition = createCondition(
                code: "R69",
                display: otherDisease
            )
            conditions.append(condition)
        }
        
        // Save conditions to patient model
        patientModel.existingConditions = conditions
    }
    
    private func createCondition(code: String, display: String) -> Condition {
        let condition = Condition(
            subject: Reference(
                reference: FHIRPrimitive(FHIRString("Patient/\(patientModel.id)"))
            )
        )
        
        // Set the code
        let coding = Coding(
            code: FHIRPrimitive(FHIRString(code)),
            display: FHIRPrimitive(FHIRString(display)),
            system: FHIRPrimitive(FHIRURI("http://hl7.org/fhir/sid/icd-10"))
        )
        condition.code = CodeableConcept(coding: [coding])
        
        // Set the clinical status
        let statusCoding = Coding(
            code: FHIRPrimitive(FHIRString("active")),
            system: FHIRPrimitive(FHIRURI("http://terminology.hl7.org/CodeSystem/condition-clinical"))
        )
        condition.clinicalStatus = CodeableConcept(coding: [statusCoding])
        
        return condition
    }
    
    private func getICD10Code(for disease: String) -> String {
        switch disease.lowercased() {
        case "heart related disorders":
            return "I51.9"  // Heart disease, unspecified
        case "lungs related disorders":
            return "J98.9"  // Respiratory disorder, unspecified
        case "diabetes":
            return "E11.9"  // Type 2 diabetes mellitus without complications
        case "thyroid disorders":
            return "E07.9"  // Disorder of thyroid, unspecified
        case "chronic kidney disease":
            return "N18.9"  // Chronic kidney disease, unspecified
        case "sleep apnea":
            return "G47.30" // Sleep apnea, unspecified
        default:
            return "R69"    // Illness, unspecified
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
        }
    }
}

#Preview {
    ExistingDiseasesView()
        .environmentObject(PatientModel())
}
