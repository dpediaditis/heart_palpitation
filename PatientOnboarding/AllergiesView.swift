//
//  AllergiesView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding
import ModelsR4

struct AllergiesView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @EnvironmentObject var patientModel: PatientModel
    @State private var hasAllergies = false
    @State private var allergies: [String] = [""]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Do you have any known allergies?")
                .font(.headline)
                .padding(.bottom, 10)
            
            Toggle("I have allergies", isOn: $hasAllergies)
                .padding(.bottom, 15)
            
            if hasAllergies {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Please list your allergies:")
                        .font(.subheadline)
                    
                    ForEach(0..<allergies.count, id: \.self) { index in
                        HStack {
                            TextField("Allergy", text: $allergies[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if index == allergies.count - 1 {
                                Button(action: {
                                    allergies.append("")
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Button(action: {
                                    allergies.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            Button("Next") {
                saveAllergies()
                onboardingNavigationPath.nextStep()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
    }
    
    private func saveAllergies() {
        var allergyResources: [AllergyIntolerance] = []
        
        if hasAllergies {
            for allergy in allergies where !allergy.trimmingCharacters(in: .whitespaces).isEmpty {
                let allergyResource = createAllergyIntolerance(allergy: allergy)
                allergyResources.append(allergyResource)
            }
        }
        
        patientModel.allergyResources = allergyResources
    }
    
    private func createAllergyIntolerance(allergy: String) -> AllergyIntolerance {
        let allergyIntolerance = AllergyIntolerance(
            patient: Reference(
                reference: FHIRPrimitive(FHIRString("Patient/\(patientModel.id)"))
            )
        )
        
        // Set clinical status
        allergyIntolerance.clinicalStatus = CodeableConcept(
            coding: [
                Coding(
                    code: FHIRPrimitive(FHIRString("active")),
                    system: FHIRPrimitive(FHIRURI("http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical"))
                )
            ]
        )
        
        // Set code
        let coding = Coding(
            code: FHIRPrimitive(FHIRString(allergy.lowercased().replacingOccurrences(of: " ", with: "-"))),
            display: FHIRPrimitive(FHIRString(allergy)),
            system: FHIRPrimitive(FHIRURI("http://snomed.info/sct"))
        )
        allergyIntolerance.code = CodeableConcept(coding: [coding])
        
        return allergyIntolerance
    }
}

#Preview {
    AllergiesView()
        .environmentObject(PatientModel())
}
