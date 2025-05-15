//
//  ConsentView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding

struct ConsentView: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @EnvironmentObject var patientModel: PatientModel
    @State private var consented = false

    var body: some View {
        VStack {
            Text("Consent to Data Collection")
                .font(.headline)
                .padding(.bottom, 10)

            ScrollView {
                Text("""
                By using this application, you agree to allow your health data to be collected and shared with your healthcare provider for the purpose of improving your care.

                Your data will be stored securely and will not be shared with third parties without your explicit consent.

                You have the right to request deletion of your data at any time by contacting our support team.

                This application is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.
                """)
                .padding(.bottom, 20)
            }

            Toggle("I agree to the terms above", isOn: $consented)
                .padding(.vertical)

            Spacer()

            HStack {
                Spacer()
                Button("Submit") {
                    onboardingNavigationPath.nextStep()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!consented)
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ConsentView()
        .environmentObject(PatientModel())
}
