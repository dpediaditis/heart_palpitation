//
//  NicotineUseView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding
import ModelsR4

struct NicotineUseView: View {
    let onComplete: () -> Void
    @EnvironmentObject var patientModel: PatientModel
    @State private var usesNicotine = false
    @State private var nicotineProduct = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Do you consume any nicotine based products?")
                .font(.headline)
                .padding(.bottom, 10)

            Toggle("I use nicotine products", isOn: $usesNicotine)
                .padding(.bottom, 15)

            if usesNicotine {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Please specify the product:")
                        .font(.subheadline)
                    TextField("e.g., cigarettes, vaping, etc.", text: $nicotineProduct)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }

            Spacer()

            Button("Next") {
                saveNicotineUse()
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
    }

    private func saveNicotineUse() {
       /* if usesNicotine {
            let observation = createNicotineObservation()
            patientModel.nicotineUse = observation
        } else {
            patientModel.nicotineUse = nil
        }*/
    }

    private func createNicotineObservation() /*-> Observation*/ {
        // LOINC 72166-2 = Tobacco smoking status
       /* if !nicotineProduct.isEmpty {
            return Observation(
                code: CodeableConcept(
                    coding: [
                        Coding(
                            code: FHIRPrimitive(FHIRString("72166-2")),
                            display: FHIRPrimitive(FHIRString("Tobacco smoking status")),
                            system: FHIRPrimitive(FHIRURI("http://loinc.org"))
                        )
                    ]
                ),
                status: FHIRPrimitive(ObservationStatus.final),
                subject: Reference(reference: FHIRPrimitive(FHIRString("Patient/\(patientModel.id)"))),
                value: .string(FHIRPrimitive(FHIRString(nicotineProduct)))
            )
        } else {
            return Observation(
                code: CodeableConcept(
                    coding: [
                        Coding(
                            code: FHIRPrimitive(FHIRString("72166-2")),
                            display: FHIRPrimitive(FHIRString("Tobacco smoking status")),
                            system: FHIRPrimitive(FHIRURI("http://loinc.org"))
                        )
                    ]
                ),
                status: FHIRPrimitive(ObservationStatus.final),
                subject: Reference(reference: FHIRPrimitive(FHIRString("Patient/\(patientModel.id)")))
            )
        }*/
    }
}

#Preview {
    NicotineUseView(onComplete: {})
        .environmentObject(PatientModel())
}
