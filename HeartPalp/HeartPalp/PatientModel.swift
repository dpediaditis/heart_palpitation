//
//  PatientModel.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

//
//  PatientModel.swift
//  PatientOnboarding
//
//  Created by HARSIMRAN KAUR on 2025-05-14.
//

import Foundation
import SwiftUI
import ModelsR4

enum Gender: String, CaseIterable, Identifiable, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
    
    var id: String { self.rawValue }
}

class PatientModel: ObservableObject {
    let id = UUID().uuidString
    
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var dateOfBirth: Date = Date()
    @Published var gender: Gender = .preferNotToSay
    
    // Allergies
    @Published var hasAllergies: Bool = false
    @Published var allergies: String = ""
    
    // FHIR resources for onboarding steps
    @Published var existingConditions: [Condition] = []
    @Published var medications: [MedicationStatement] = []
    @Published var allergyResources: [AllergyIntolerance] = []
    @Published var nicotineUse: Observation? = nil
    @Published var pregnancyStatus: Observation? = nil
    
    var fullName: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
        if !trimmedFirst.isEmpty && !trimmedLast.isEmpty {
            return "\(trimmedFirst) \(trimmedLast)"
        } else if !trimmedFirst.isEmpty {
            return trimmedFirst
        } else {
            return trimmedLast
        }
    }
    
    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year ?? 0
    }
    
    func savePatientData() {
        let defaults = UserDefaults.standard
        defaults.set(firstName, forKey: "patientFirstName")
        defaults.set(lastName, forKey: "patientLastName")
        defaults.set(dateOfBirth, forKey: "patientDateOfBirth")
        defaults.set(gender.rawValue, forKey: "patientGender")
        defaults.set(hasAllergies, forKey: "hasAllergies")
        defaults.set(allergies, forKey: "allergies")
    }
    
    func loadPatientData() {
        let defaults = UserDefaults.standard
        firstName = defaults.string(forKey: "patientFirstName") ?? ""
        lastName = defaults.string(forKey: "patientLastName") ?? ""
        dateOfBirth = defaults.object(forKey: "patientDateOfBirth") as? Date ?? Date()
        
        if let genderString = defaults.string(forKey: "patientGender"),
           let loadedGender = Gender(rawValue: genderString) {
            gender = loadedGender
        }
        
        hasAllergies = defaults.bool(forKey: "hasAllergies")
        allergies = defaults.string(forKey: "allergies") ?? ""
    }
    
    // MARK: - Medications Persistence
    
    func saveMedications(from names: [String]) {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let defaults = UserDefaults.standard
        defaults.set(trimmed, forKey: "patientMedications")
        
        // We'll just store the names as strings and not try to create FHIR objects
        // which have complex requirements
    }
    
    func loadMedications() -> [String] {
        let defaults = UserDefaults.standard
        if let saved = defaults.stringArray(forKey: "patientMedications") {
            return saved
        }
        return []
    }
    
    func generatePatientId() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let birthDateString = dateFormatter.string(from: dateOfBirth)
        
        // Create a readable ID with the format: symptom-saga-id-firstname-lastname-birthdate
        let id = "symptom-saga-id-\(firstName.lowercased())-\(lastName.lowercased())-\(birthDateString)"
        
        print("🔑 Generated Patient ID: \(id)")
        print("  - First Name: \(firstName)")
        print("  - Last Name: \(lastName)")
        print("  - Birth Date: \(birthDateString)")
        
        return id
    }
}
