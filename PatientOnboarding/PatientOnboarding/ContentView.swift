//
//  ContentView.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import Spezi

struct ContentView: View {
    @EnvironmentObject var patientModel: PatientModel

    var body: some View {
        NavigationStack {
            VStack {
                // Patient info section
                if !patientModel.firstName.isEmpty || !patientModel.lastName.isEmpty {
                    PatientInfoCard(patientModel: patientModel)
                        .padding()
                }

                // Main content - placeholder or your actual content
                Text("Main app content goes here")
                    .font(.title)
                    .padding()
            }
            .navigationTitle("Heart Survey")
            .onAppear {
                patientModel.loadPatientData()
            }
        }
    }
}

struct PatientInfoCard: View {
    let patientModel: PatientModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Patient Information")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name: \(patientModel.fullName)")
                    Text("Age: \(patientModel.age)")
                    Text("Gender: \(patientModel.gender.rawValue)")
                }
                Spacer()

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
