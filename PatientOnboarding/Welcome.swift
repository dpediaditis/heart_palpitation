//
//  Welcome.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import SwiftUI
import SpeziOnboarding

struct Welcome: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    @EnvironmentObject var patientModel: PatientModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var showAccountSheet = false
    @State private var showLoginSheet = false
    @State private var email = ""
    @State private var password = ""
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    @State private var showEmailError = false
    @State private var showLoginError = false

    var body: some View {
        VStack(spacing: 48) {
            // Heart + Title + Tagline
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "heart.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.red)
                VStack(alignment: .leading, spacing: 10) {
                    Text("WELCOME to PULSECARE")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Connected care, wherever you are!")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 50)

            // Features List
            VStack(alignment: .leading, spacing: 26) {
                featureRow(emoji: "🩺", bold: "Track", rest: "heart health and symptoms easily—anytime, anywhere.")
                featureRow(emoji: "🔗", bold: "Connect", rest: "your wearable to fetch your health data.")
                featureRow(emoji: "📝", bold: "Feel a symptom?", rest: "Record it instantly—with just a few taps.")
                featureRow(emoji: "📊", bold: "See your health data", rest: "in a clear timeline and spot patterns.")
                featureRow(emoji: "📤", bold: "Download & share", rest: "your data securely with your care provider.")
                featureRow(emoji: "🔐", bold: "Your privacy matters", rest: "all your data is stored securely and only shared with your consent.")
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button("Create Account") {
                    showAccountSheet = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                Button("Login") {
                    showLoginSheet = true
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("Continue as Guest") {
                    onboardingNavigationPath.nextStep()
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showAccountSheet) {
            accountSheet
        }
        .sheet(isPresented: $showLoginSheet) {
            loginSheet
        }
    }

    // MARK: - Feature Row Helper
    func featureRow(emoji: String, bold: String, rest: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
                .font(.title2)
                .padding(.top, 1)
            (
                Text(bold).bold() +
                Text(" ") +
                Text(rest).italic()
            )
            .font(.body)
        }
    }

    // MARK: - Account Sheet
    var accountSheet: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.title2)
                .padding(.top)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if showEmailError {
                Text("Please enter a valid email and password.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Create Account") {
                if isValidEmail(email) && !password.isEmpty {
                    UserDefaults.standard.set(email, forKey: "userEmail")
                    UserDefaults.standard.set(password, forKey: "userPassword")
                    showAccountSheet = false
                    onboardingNavigationPath.nextStep()
                } else {
                    showEmailError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            Button("Cancel") {
                showAccountSheet = false
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    // MARK: - Login Sheet
    var loginSheet: some View {
        VStack(spacing: 20) {
            Text("Login")
                .font(.title2)
                .padding(.top)

            TextField("Email", text: $loginEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $loginPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            if showLoginError {
                Text("Invalid email or password.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Login") {
                let savedEmail = UserDefaults.standard.string(forKey: "userEmail")
                let savedPassword = UserDefaults.standard.string(forKey: "userPassword")
                if loginEmail == savedEmail && loginPassword == savedPassword {
                    hasCompletedOnboarding = true
                    showLoginSheet = false
                } else {
                    showLoginError = true
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            Button("Cancel") {
                showLoginSheet = false
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
}

#Preview {
    Welcome()
        .environmentObject(PatientModel())
}
