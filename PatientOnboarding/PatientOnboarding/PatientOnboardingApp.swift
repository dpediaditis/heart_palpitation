//
//  PatientOnboardingApp.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI

@main
struct PatientOnboardingApp: App {
    @StateObject private var patientModel = PatientModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(patientModel)
            } else {
                PatientOnboardingFlow()
                    .environmentObject(patientModel)
            }
        }
    }
}
