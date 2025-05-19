import Foundation

struct AppConfig {
    // MARK: - Patient Configuration
    static var patientId: String {
        get {
            UserDefaults.standard.string(forKey: "patientId") ?? "unknown-patient"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "patientId")
            print("💾 Saved patient ID: \(newValue)")
        }
    }
    
    // MARK: - FHIR Configuration
    static var patientReference: String {
        "Patient/\(patientId)"
    }
} 