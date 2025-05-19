import Foundation

struct AppConfig {
    // MARK: - Patient Configuration
    static let patientId = "example-patient-id-anton2"
    
    // MARK: - FHIR Configuration
    static var patientReference: String {
        "Patient/\(patientId)"
    }
} 