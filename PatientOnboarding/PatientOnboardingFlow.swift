//
//  PatientOnboardingFlow.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding

struct PatientOnboardingFlow: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var patientModel = PatientModel()

    var body: some View {
        OnboardingStack(onboardingFlowComplete: $hasCompletedOnboarding) {
            Welcome()
                .environmentObject(patientModel)
            BasicInfoView()
                .environmentObject(patientModel)
            ExistingDiseasesView()
                .environmentObject(patientModel)
            MedicationsView()
                .environmentObject(patientModel)
            AllergiesView()
                .environmentObject(patientModel)
            NicotineUseView()
                .environmentObject(patientModel)
            PregnancyView()
                .environmentObject(patientModel)
            ConsentView()
                .environmentObject(patientModel)
            ThankYouView()
        }
        .environmentObject(patientModel)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(!hasCompletedOnboarding)
    }
}

struct ThankYouView: View {
    var body: some View {
        VStack {
            Text("Thank you for completing the onboarding process!")
                .font(.headline)
                .padding()
        }
    }
}

#Preview {
    PatientOnboardingFlow()
}
