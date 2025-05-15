//
//  PregnancyView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding
import ModelsR4

struct PregnancyView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @EnvironmentObject var patientModel: PatientModel
    @State private var pregnancyStatus = "Not pregnant"

    let pregnancyOptions = [
        "Not pregnant",
        "Pregnant",
        "Not applicable"
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Pregnancy Status")
                .font(.headline)
                .padding(.bottom, 10)

            Text("This question is only for female patients. If not applicable, please select 'Not applicable'.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)

            ForEach(pregnancyOptions, id: \.self) { option in
                Button(action: {
                    pregnancyStatus = option
                }) {
                    HStack {
                        Image(systemName: pregnancyStatus == option ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(pregnancyStatus == option ? .blue : .gray)

                        Text(option)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            HStack {
                Spacer()
                Button("Next") {
                    savePregnancyStatus()
                    onboardingNavigationPath.nextStep()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    private func savePregnancyStatus() {
        if pregnancyStatus == "Pregnant" {
            // Create a FHIR Observation for pregnancy
            let observation = Observation(
                code: CodeableConcept(
                    coding: [
                        Coding(
                            code: FHIRPrimitive(FHIRString("82810-3")),
                            display: FHIRPrimitive(FHIRString("Pregnancy status")),
                            system: FHIRPrimitive(FHIRURI("http://loinc.org"))
                        )
                    ]
                ), status: FHIRPrimitive(ObservationStatus.final),
                subject: Reference(
                    reference: FHIRPrimitive(FHIRString("Patient/\(patientModel.id)"))
                ),
                value: .codeableConcept(
                    CodeableConcept(
                        coding: [
                            Coding(
                                code: FHIRPrimitive(FHIRString("77386006")),
                                display: FHIRPrimitive(FHIRString("Pregnant")),
                                system: FHIRPrimitive(FHIRURI("http://snomed.info/sct"))
                            )
                        ],
                        text: FHIRPrimitive(FHIRString("Pregnant"))
                    )
                )
            )
            patientModel.pregnancyStatus = observation
        } else if pregnancyStatus == "Not pregnant" {
            // Create a FHIR Observation for not pregnant
            let observation = Observation(
                code: CodeableConcept(
                    coding: [
                        Coding(
                            code: FHIRPrimitive(FHIRString("82810-3")),
                            display: FHIRPrimitive(FHIRString("Pregnancy status")),
                            system: FHIRPrimitive(FHIRURI("http://loinc.org"))
                        )
                    ]
                ), status: FHIRPrimitive(ObservationStatus.final),
                subject: Reference(
                    reference: FHIRPrimitive(FHIRString("Patient/\(patientModel.id)"))
                ),
                value: .codeableConcept(
                    CodeableConcept(
                        coding: [
                            Coding(
                                code: FHIRPrimitive(FHIRString("60001007")),
                                display: FHIRPrimitive(FHIRString("Not pregnant")),
                                system: FHIRPrimitive(FHIRURI("http://snomed.info/sct"))
                            )
                        ],
                        text: FHIRPrimitive(FHIRString("Not pregnant"))
                    )
                )
            )
            patientModel.pregnancyStatus = observation
        } else {
            // Not applicable - set to nil or create observation with "not applicable" value
            patientModel.pregnancyStatus = nil
        }
        
        // Save to UserDefaults as well if needed
        UserDefaults.standard.set(pregnancyStatus, forKey: "pregnancyStatus")
    }
}

#Preview {
    PregnancyView()
        .environmentObject(PatientModel())
}
