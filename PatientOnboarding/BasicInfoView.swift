//
//  BasicInfoView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding

struct BasicInfoView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
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
                    onboardingNavigationPath.nextStep()
                }
                .buttonStyle(.borderedProminent)
                .disabled(patientModel.firstName.isEmpty || patientModel.lastName.isEmpty)
            }
            .padding()
        }
    }
}

#Preview {
    BasicInfoView()
        .environmentObject(PatientModel())
}
