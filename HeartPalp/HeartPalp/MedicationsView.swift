//
//  MedicationsView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding
import ModelsR4

struct MedicationsView: View {
    let onComplete: () -> Void
    @EnvironmentObject private var patientModel: PatientModel
    @State private var takesMedications = false
    @State private var medications: [String] = [""]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Do you take any medications?")
                .font(.headline)
                .padding(.bottom, 10)

            Toggle("I take medications", isOn: $takesMedications)
                .padding(.bottom, 15)

            if takesMedications {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Please list your medications:")
                        .font(.subheadline)

                    ForEach(0..<medications.count, id: \.self) { index in
                        HStack {
                            TextField("Medication name", text: $medications[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            if index == medications.count - 1 {
                                Button(action: {
                                    medications.append("")
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Button(action: {
                                    medications.remove(at: index)
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
                patientModel.saveMedications(from: medications)
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding()
        }
        .padding()
    }
}

#Preview {
    MedicationsView(onComplete: {})
        .environmentObject(PatientModel())
}
