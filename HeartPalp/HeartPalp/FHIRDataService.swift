import Foundation
import HealthKit
import SwiftUI

/// A service to handle FHIR-formatted data export and API communication using FHIR Bundles
class FHIRDataService: ObservableObject {
    @Published var isUploading = false
    @Published var lastSyncDate: Date?

    //private let serverURL = "http://localhost:8080/fhir"
    private let serverURL = "https://gw.interop.community/hp2025stan/open"
    private let healthStore = HKHealthStore()

    /// Create a basic Patient resource (once)
    func createPatient() async throws {
        let patient: [String: Any] = [
            "resourceType": "Patient",
            "id": "example-patient-id3",
            "name": [[
                "given": ["Atmos"],
                "family": "Aaron"
            ]],
            "gender" : "male",
            "birthDate" : "1991-01-20"
        ]
        let url = URL(string: "\(serverURL)/Patient/example-patient-id3")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: patient)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("👤 Patient Status: \(httpResponse.statusCode)")
        }
    }
    
    /// Posts a completed QuestionnaireResponse payload to the FHIR server
    func uploadQuestionnaireResponse(_ jsonData: Data) async throws {
        let url = URL(string: "\(serverURL)/QuestionnaireResponse")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Not an HTTP response")
            throw FHIRError.uploadFailed
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("""
            ❌ QuestionnaireResponse upload failed
              Status: \(httpResponse.statusCode)
              Body:
            \(body)
            """)
            throw FHIRError.uploadFailed
        }

        print("✅ QuestionnaireResponse posted: \(httpResponse.statusCode)")
    }


    /// Upload all health data in a single FHIR transaction Bundle,
    /// with ECG waveform encoded as SampledData
    func uploadAllHealthData(
        hrSamples: [HKQuantitySample],
        restingSamples: [HKQuantitySample],
        oxygenSamples: [HKQuantitySample],
        stepSamples: [HKQuantitySample],
        energySamples: [HKQuantitySample],
        exerciseSamples: [HKQuantitySample],
        standSamples: [HKQuantitySample],
        glucoseSamples: [HKQuantitySample],
        ecgSamples: [HKElectrocardiogram]
    ) async throws {
        try await createPatient()
        let patientRef = FHIRReference(reference: "Patient/example-patient-id3")

        // Build Observation resources
        var entries: [FHIRBundleEntry] = []

        // Helper for quantity-based Observations
        func makeQuantityEntry(
            sample: HKQuantitySample,
            loinc: String, display: String,
            readingUnit: HKUnit,
            fhirUnit: String, fhirCode: String,
            transform: (Double) -> Double = { $0 }
        ) {
            let raw = sample.quantity.doubleValue(for: readingUnit)
            let value = transform(raw)
            let obs = FHIRObservation(
                status: "final",
                code: FHIRCodeableConcept(coding: [
                    FHIRCoding(system: "http://loinc.org", code: loinc, display: display)
                ]),
                subject: patientRef,
                effectiveDateTime: sample.startDate.iso8601String(),
                valueQuantity: FHIRQuantity(value: value, unit: fhirUnit, system: "http://unitsofmeasure.org", code: fhirCode)
            )
            entries.append(
                FHIRBundleEntry(request: FHIRBundleRequest(method: "POST", url: "Observation"), resource: obs)
            )
        }

        // Vitals & activity & glucose
        hrSamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "8867-4", display: "Heart rate",
                               readingUnit: .count().unitDivided(by: .minute()),
                               fhirUnit: "beats/minute", fhirCode: "/min")
        }
        restingSamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "40443-4", display: "Resting heart rate",
                               readingUnit: .count().unitDivided(by: .minute()),
                               fhirUnit: "beats/minute", fhirCode: "/min")
        }
        oxygenSamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "59408-5", display: "Oxygen saturation",
                               readingUnit: .percent(), fhirUnit: "%", fhirCode: "%")
        }
        stepSamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "41950-7", display: "Step count",
                               readingUnit: .count(), fhirUnit: "count", fhirCode: "{count}")
        }
        energySamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "41956-7", display: "Active energy burned",
                               readingUnit: .kilocalorie(), fhirUnit: "kcal", fhirCode: "kcal")
        }
        exerciseSamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "54128-8", display: "Exercise duration",
                               readingUnit: .minute(), fhirUnit: "min", fhirCode: "min")
        }
        standSamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "55417-6", display: "Stand duration",
                               readingUnit: .minute(), fhirUnit: "min", fhirCode: "min")
        }
        let mmolPerL = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose)
            .unitDivided(by: .liter())
        glucoseSamples.forEach {
            makeQuantityEntry(sample: $0,
                               loinc: "2339-0", display: "Glucose",
                               readingUnit: mmolPerL,
                               fhirUnit: "mg/dL", fhirCode: "mg/dL",
                               transform: { $0 * 18.0 })
        }

        // ECG waveform as SampledData
        for ecg in ecgSamples {
            var volts = [Double]()
            var times = [TimeInterval]()
            let startDate = ecg.startDate
            let sem = DispatchSemaphore(value: 0)
            let query = HKElectrocardiogramQuery(ecg) { _, result in
                switch result {
                case .measurement(let m):
                    if let q = m.quantity(for: .appleWatchSimilarToLeadI) {
                        volts.append(q.doubleValue(for: .volt()) * 1000)
                        times.append(m.timeSinceSampleStart)
                    }
                case .done, .error:
                    sem.signal()
                }
            }
            healthStore.execute(query)
            sem.wait()

            guard volts.count > 1 else { continue }
            // compute mean period (in ms)
            let intervals = zip(times.dropFirst(), times).map(-)
            let meanSeconds = intervals.reduce(0, +) / Double(intervals.count)
            let periodMs = meanSeconds * 1000.0

            // build whitespace-separated data string
            let dataString = volts.map { String(format: "%.3f", $0) }.joined(separator: " ")

            let sampled = FHIRSampledData(
                origin: FHIRQuantity(value: volts.first!, unit: "mV", system: "http://unitsofmeasure.org", code: "mV"),
                period: periodMs,
                periodUnit: "ms",
                factor: nil,
                lowerLimit: volts.min(),
                upperLimit: volts.max(),
                dimensions: 1,
                data: dataString
            )

            var ecgObs = FHIRObservation(
                status: "final",
                code: FHIRCodeableConcept(coding: [
                    FHIRCoding(system: "http://loinc.org", code: "131328-4", display: "ECG rhythm strip")
                ]),
                subject: patientRef,
                effectiveDateTime: startDate.iso8601String()
            )
            ecgObs.component = [FHIRObservationComponent(
                code: FHIRCodeableConcept(coding: [
                    FHIRCoding(system: "http://loinc.org", code: "51985-6", display: "ECG lead I voltage")
                ]),
                valueSampledData: sampled
            )]

            entries.append(
                FHIRBundleEntry(request: FHIRBundleRequest(method: "POST", url: "Observation"), resource: ecgObs)
            )
        }

        // Build and POST transaction Bundle
        let bundle = FHIRBundle(type: "transaction", entry: entries)
        let bundleURL = URL(string: serverURL)!
        var bundleReq = URLRequest(url: bundleURL)
        bundleReq.httpMethod = "POST"
        bundleReq.addValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        bundleReq.httpBody = try JSONEncoder().encode(bundle)

        let (_, response) = try await URLSession.shared.data(for: bundleReq)
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Bundle POST status: \(httpResponse.statusCode)")
        }
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw FHIRError.uploadFailed
        }

        DispatchQueue.main.async { self.lastSyncDate = Date() }
    }
}

// MARK: - FHIR Models

enum FHIRError: Error { case uploadFailed }

struct FHIRObservation: Codable {
    let resourceType = "Observation"
    let status: String
    let code: FHIRCodeableConcept
    let subject: FHIRReference
    let effectiveDateTime: String
    var valueQuantity: FHIRQuantity?
    var valueString: String?
    var component: [FHIRObservationComponent]? = nil
}

struct FHIRObservationComponent: Codable {
    let code: FHIRCodeableConcept
    var valueQuantity: FHIRQuantity?
    var valueString: String?
    var valueSampledData: FHIRSampledData?
}

struct FHIRSampledData: Codable {
    let origin: FHIRQuantity
    let period: Double
    let periodUnit: String    // added unit for period
    let factor: Double?
    let lowerLimit: Double?
    let upperLimit: Double?
    let dimensions: Int
    let data: String
}

struct FHIRCodeableConcept: Codable { let coding: [FHIRCoding] }
struct FHIRCoding: Codable { let system: String; let code: String; let display: String }
struct FHIRQuantity: Codable { let value: Double; let unit, system, code: String }
struct FHIRReference: Codable { let reference: String }

struct FHIRBundle: Encodable {
    let resourceType = "Bundle"
    let type: String
    let entry: [FHIRBundleEntry]
}
struct FHIRBundleEntry: Encodable {
    let request: FHIRBundleRequest
    let resource: Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(request, forKey: .request)
        try resource.encode(to: container.superEncoder(forKey: .resource))
    }

    enum CodingKeys: String, CodingKey {
        case request, resource
    }
}
struct FHIRBundleRequest: Codable {
    let method: String
    let url: String
}

// Date extension for fractional seconds
extension Date {
    func iso8601String() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: self)
    }
}
