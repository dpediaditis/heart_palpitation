//
//  BasicInfoView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding

struct BasicInfoView: View {
    let onComplete: () -> Void
    @EnvironmentObject var patientModel: PatientModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Personal Information")
                .font(.title)
                .padding(.top)

            Form {
                Section(header: Text("Name")) {
                    TextField("First Name", text: $patientModel.firstName)
                    TextField("Last Name", text: $patientModel.lastName)
                }

                Section(header: Text("Date of Birth")) {
                    DatePicker("", selection: $patientModel.dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }

                Section(header: Text("Gender")) {
                    Picker("Select gender", selection: $patientModel.gender) {
                        ForEach(Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            HStack {
                Spacer()
                Button("Continue") {
                    // Generate and save patient ID
                    let patientId = patientModel.generatePatientId()
                    AppConfig.patientId = patientId
                    
                    // Save patient information
                    UserDefaults.standard.set(patientModel.firstName, forKey: "patientFirstName")
                    UserDefaults.standard.set(patientModel.lastName, forKey: "patientLastName")
                    UserDefaults.standard.set(patientModel.dateOfBirth, forKey: "patientDateOfBirth")
                    UserDefaults.standard.set(patientModel.gender.rawValue, forKey: "patientGender")
                    
                    print("✅ Saved patient information:")
                    print("  - First Name: \(patientModel.firstName)")
                    print("  - Last Name: \(patientModel.lastName)")
                    print("  - Date of Birth: \(patientModel.dateOfBirth)")
                    print("  - Gender: \(patientModel.gender.rawValue)")
                    
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .disabled(patientModel.firstName.isEmpty || patientModel.lastName.isEmpty)
            }
            .padding()
        }
    }
}

#Preview {
    BasicInfoView(onComplete: {})
        .environmentObject(PatientModel())
}
