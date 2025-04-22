import Foundation
import HealthKit
import SwiftUI

/// A service to handle FHIR-formatted data export and API communication
class FHIRDataService: ObservableObject {
    @Published var isUploading = false
    @Published var lastSyncDate: Date?

    private let serverURL = "http://localhost:8080/fhir"


    /// Create a basic Patient resource (once)
    func createPatient() async throws {
        let patient: [String: Any] = [
            "resourceType": "Patient",
            "id": "example-patient-id",
            "name": [[
                "given": ["Test"],
                "family": "User"
            ]]
        ]

        let url = URL(string: "\(serverURL)/Patient/example-patient-id")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: patient)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("👤 Patient Status: \(httpResponse.statusCode)")
        }

        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            print("👤 Patient Response JSON: \(json)")
        }
    }

    /// Upload multiple health data samples to the FHIR server
    func uploadAllHealthData(
        hrSamples: [HKQuantitySample],
        restingSamples: [HKQuantitySample],
        oxygenSamples: [HKQuantitySample]
    ) async throws {
        try await createPatient() // ensure patient exists first

        let patientReference = FHIRReference(reference: "Patient/example-patient-id")

        var observations: [FHIRObservation] = []

        // Heart rate samples
        for sample in hrSamples {
            let obs = FHIRObservation(
                status: "final",
                code: FHIRCodeableConcept(coding: [FHIRCoding(system: "http://loinc.org", code: "8867-4", display: "Heart rate")]),
                subject: patientReference,
                effectiveDateTime: sample.startDate.iso8601String(),
                valueQuantity: FHIRQuantity(
                    value: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute())),
                    unit: "beats/minute",
                    system: "http://unitsofmeasure.org",
                    code: "/min"
                )
            )
            observations.append(obs)
        }

        // Resting heart rate samples
        for sample in restingSamples {
            let obs = FHIRObservation(
                status: "final",
                code: FHIRCodeableConcept(coding: [FHIRCoding(system: "http://loinc.org", code: "40443-4", display: "Resting heart rate")]),
                subject: patientReference,
                effectiveDateTime: sample.startDate.iso8601String(),
                valueQuantity: FHIRQuantity(
                    value: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute())),
                    unit: "beats/minute",
                    system: "http://unitsofmeasure.org",
                    code: "/min"
                )
            )
            observations.append(obs)
        }

        // Blood oxygen samples
        for sample in oxygenSamples {
            let obs = FHIRObservation(
                status: "final",
                code: FHIRCodeableConcept(coding: [FHIRCoding(system: "http://loinc.org", code: "59408-5", display: "Oxygen saturation")]),
                subject: patientReference,
                effectiveDateTime: sample.startDate.iso8601String(),
                valueQuantity: FHIRQuantity(
                    value: sample.quantity.doubleValue(for: .percent()) * 100,
                    unit: "%",
                    system: "http://unitsofmeasure.org",
                    code: "%"
                )
            )
            observations.append(obs)
        }

        for obs in observations {
            try await uploadObservation(obs)
        }

        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
    }

    private func uploadObservation(_ observation: FHIRObservation) async throws {
        let url = URL(string: "\(serverURL)/Observation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(observation)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status code: \(httpResponse.statusCode)")
        }

        if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            print("🧾 Response JSON: \(json)")
        } else {
            print("❌ Unable to decode server response.")
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FHIRError.uploadFailed
        }
    }
}

// MARK: - FHIR Models

enum FHIRError: Error {
    case uploadFailed
}

struct FHIRObservation: Codable {
    let resourceType = "Observation"
    let status: String
    let code: FHIRCodeableConcept
    let subject: FHIRReference
    let effectiveDateTime: String
    var valueQuantity: FHIRQuantity?
    var valueString: String? = nil
    var component: [FHIRObservationComponent]? = nil
}

struct FHIRObservationComponent: Codable {
    let code: FHIRCodeableConcept
    var valueQuantity: FHIRQuantity?
    var valueString: String?
}

struct FHIRCodeableConcept: Codable {
    let coding: [FHIRCoding]
}

struct FHIRCoding: Codable {
    let system: String
    let code: String
    let display: String
}

struct FHIRQuantity: Codable {
    let value: Double
    let unit: String
    let system: String
    let code: String
}

struct FHIRReference: Codable {
    let reference: String
}

// MARK: - Date Extension

extension Date {
    func iso8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}
