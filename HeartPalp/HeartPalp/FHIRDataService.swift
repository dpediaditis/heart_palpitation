import Foundation
import HealthKit
import SwiftUI

// MARK: - Type‑Erased FHIR Resource Wrapper
/// Wrap any Encodable FHIR resource so it encodes properly
struct AnyFHIRResource: Encodable {
    private let _encode: (Encoder) throws -> Void
    init<T: Encodable>(_ resource: T) { _encode = resource.encode }
    func encode(to encoder: Encoder) throws { try _encode(encoder) }
}

// MARK: - Minimal Patient Model
struct FHIRPatient: Encodable {
    let resourceType = "Patient"
    let id: String
    let name: [HumanName]
    let gender: String
    let birthDate: String

    struct HumanName: Encodable {
        let given: [String]
        let family: String
    }
}

// MARK: - Bundle Entry and Request
struct FHIRBundleEntry: Encodable {
    let request: FHIRBundleRequest
    let resource: AnyFHIRResource
}

struct FHIRBundleRequest: Codable {
    let method: String
    let url: String
}

// MARK: - Transaction Bundle
struct FHIRBundle: Encodable {
    let resourceType = "Bundle"
    let type: String
    let entry: [FHIRBundleEntry]
}

// MARK: - Observation Resource
/// Custom encode(to:) ensures nil optionals are omitted
struct FHIRObservation: Encodable {
    let resourceType = "Observation"
    let status: String
    let code: FHIRCodeableConcept
    let subject: FHIRReference
    let effectiveDateTime: String
    var valueQuantity: FHIRQuantity?
    var valueString: String?
    var component: [FHIRObservationComponent]?

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(resourceType,         forKey: .resourceType)
        try c.encode(status,               forKey: .status)
        try c.encode(code,                 forKey: .code)
        try c.encode(subject,              forKey: .subject)
        try c.encode(effectiveDateTime,    forKey: .effectiveDateTime)
        try c.encodeIfPresent(valueQuantity, forKey: .valueQuantity)
        try c.encodeIfPresent(valueString,   forKey: .valueString)
        try c.encodeIfPresent(component,     forKey: .component)
    }

    private enum CodingKeys: String, CodingKey {
        case resourceType, status, code, subject, effectiveDateTime
        case valueQuantity, valueString, component
    }
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
    let periodUnit: String
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

// MARK: - Helpers
extension Date {
    func iso8601String() -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt.string(from: self)
    }
}

extension HKElectrocardiogram.Classification {
    var description: String {
        switch self {
        case .notSet:                return "Not Set"
        case .sinusRhythm:          return "Sinus Rhythm"
        case .atrialFibrillation:   return "Atrial Fibrillation"
        case .inconclusiveLowHeartRate:  return "Inconclusive: Low Heart Rate"
        case .inconclusiveHighHeartRate: return "Inconclusive: High Heart Rate"
        case .inconclusivePoorReading:    return "Inconclusive: Poor Reading"
        case .inconclusiveOther:          return "Inconclusive: Other Reason"
        @unknown default:                 return "Unknown"
        }
    }
}

// MARK: - FHIR Data Service
class FHIRDataService: ObservableObject {
    @Published var isUploading = false
    @Published var lastSyncDate: Date?

    private let baseURL: String
    private let session: URLSession
    private let healthStore = HKHealthStore()

    init(baseURL: String = "https://gw.interop.community/hp2025stan/open") {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    /// Upload all health data in a single FHIR transaction Bundle
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
        // 1️⃣ Prepare patient reference and bundle entries
        let patientId = "real-patient-id"
        let patientRef = FHIRReference(reference: "Patient/\(patientId)")
        var entries: [FHIRBundleEntry] = []

        // 2️⃣ Upsert Patient as first entry
        let patientResource = FHIRPatient(
            id: patientId,
            name: [ .init(given: ["Emil"], family: "James") ],
            gender: "male",
            birthDate: "1996-04-01"
        )
        entries.append(
            FHIRBundleEntry(
                request: FHIRBundleRequest(method: "PUT", url: "Patient/\(patientId)"),
                resource: AnyFHIRResource(patientResource)
            )
        )

        // 3️⃣ Quantity Observations helper
        func makeQuantityEntry(
            sample: HKQuantitySample,
            loinc: String, display: String,
            readingUnit: HKUnit,
            fhirUnit: String, fhirCode: String,
            transform: (Double) -> Double = { $0 }
        ) {
            let raw   = sample.quantity.doubleValue(for: readingUnit)
            let value = transform(raw)
            let obs = FHIRObservation(
                status: "final",
                code: FHIRCodeableConcept(coding: [ FHIRCoding(system: "http://loinc.org", code: loinc, display: display) ]),
                subject: patientRef,
                effectiveDateTime: sample.startDate.iso8601String(),
                valueQuantity: FHIRQuantity(value: value, unit: fhirUnit, system: "http://unitsofmeasure.org", code: fhirCode),
                valueString: nil,
                component: nil
            )
            entries.append(
                FHIRBundleEntry(
                    request: FHIRBundleRequest(method: "POST", url: "Observation"),
                    resource: AnyFHIRResource(obs)
                )
            )
        }

        // 4️⃣ Add each quantity sample
        hrSamples.forEach { makeQuantityEntry(sample: $0, loinc: "8867-4", display: "Heart rate", readingUnit: .count().unitDivided(by: .minute()), fhirUnit: "beats/minute", fhirCode: "/min") }
        restingSamples.forEach { makeQuantityEntry(sample: $0, loinc: "40443-4", display: "Resting heart rate",readingUnit: .count().unitDivided(by: .minute()),fhirUnit: "beats/minute",fhirCode: "/min") }
        oxygenSamples.forEach { makeQuantityEntry(sample: $0, loinc: "59408-5", display: "Oxygen saturation",readingUnit: .percent(),fhirUnit: "%",fhirCode: "%") }
        stepSamples.forEach { makeQuantityEntry(sample: $0, loinc: "41950-7", display: "Step count",readingUnit: .count(),fhirUnit: "count",fhirCode: "{count}") }
        energySamples.forEach { makeQuantityEntry(sample: $0, loinc: "41956-7", display: "Active energy burned",readingUnit: .kilocalorie(),fhirUnit: "kcal",fhirCode: "kcal") }
        exerciseSamples.forEach { makeQuantityEntry(sample: $0, loinc: "54128-8", display: "Exercise duration",readingUnit: .minute(),fhirUnit: "min",fhirCode: "min") }
        standSamples.forEach { makeQuantityEntry(sample: $0, loinc: "55417-6", display: "Stand duration",readingUnit: .minute(),fhirUnit: "min",fhirCode: "min") }
        let mmolPerL = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: .liter())
        glucoseSamples.forEach { makeQuantityEntry(sample: $0, loinc: "2339-0", display: "Glucose",readingUnit: mmolPerL,fhirUnit: "mg/dL",fhirCode: "mg/dL", transform: { $0 * 18.0 }) }

        // 5️⃣ ECG waveform + classification + heart rate
        for ecg in ecgSamples {
            var volts = [Double](), times = [TimeInterval]()
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

            let intervals = zip(times.dropFirst(), times).map(-)
            let meanMs   = (intervals.reduce(0, +) / Double(intervals.count)) * 1000
            let dataString = volts.map { String(format: "%.3f", $0) }.joined(separator: " ")

            let sampled = FHIRSampledData(origin: FHIRQuantity(value: volts.first!, unit: "mV", system: "http://unitsofmeasure.org", code: "mV"), period: meanMs, periodUnit: "ms", factor: nil, lowerLimit: volts.min(), upperLimit: volts.max(), dimensions: 1, data: dataString)

            var ecgObs = FHIRObservation(
                status: "final",
                code: FHIRCodeableConcept(coding: [ FHIRCoding(system: "http://loinc.org", code: "131328-4", display: "ECG rhythm strip") ]),
                subject: patientRef,
                effectiveDateTime: startDate.iso8601String(),
                valueQuantity: nil,
                valueString: nil,
                component: []
            )
            ecgObs.component?.append(
                FHIRObservationComponent(code: FHIRCodeableConcept(coding: [ FHIRCoding(system: "http://loinc.org", code: "51985-6", display: "ECG lead I voltage") ]), valueQuantity: nil, valueString: nil, valueSampledData: sampled)
            )
            // classification
            if ecg.classification != .notSet {
                let desc = ecg.classification.description
                ecgObs.component?.append(
                    FHIRObservationComponent(code: FHIRCodeableConcept(coding: [ FHIRCoding(system: "http://hl7.org/fhir/ValueSet/ecg-classification", code: String(ecg.classification.rawValue), display: desc) ]), valueQuantity: nil, valueString: desc, valueSampledData: nil)
                )
            }
            // heart rate
            if #available(iOS 16.0, *), let hr = ecg.averageHeartRate?.doubleValue(for: .count().unitDivided(by: .minute())) {
                ecgObs.component?.append(
                    FHIRObservationComponent(code: FHIRCodeableConcept(coding: [ FHIRCoding(system: "http://loinc.org", code: "8867-4", display: "Heart rate") ]), valueQuantity: FHIRQuantity(value: hr, unit: "beats/minute", system: "http://unitsofmeasure.org", code: "/min"), valueString: nil, valueSampledData: nil)
                )
            }

            // append ECG entry
            entries.append(
                FHIRBundleEntry(request: FHIRBundleRequest(method: "POST", url: "Observation"), resource: AnyFHIRResource(ecgObs))
            )
        }

        // 6️⃣ POST transaction bundle
        let bundle = FHIRBundle(type: "transaction", entry: entries)
        var bundleReq = URLRequest(url: URL(string: baseURL)!)
        bundleReq.httpMethod = "POST"
        bundleReq.setValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        bundleReq.httpBody = try JSONEncoder().encode(bundle)

        let (data, response) = try await session.data(for: bundleReq)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        print("📡 Bundle POST status: \(httpResponse.statusCode)")
        if httpResponse.statusCode >= 400, let body = String(data: data, encoding: .utf8) {
            print("📨 FHIR server error body:\n\(body)")
            throw URLError(.badServerResponse)
        }
        DispatchQueue.main.async { self.lastSyncDate = Date() }
    }

    /// Posts a completed QuestionnaireResponse
    func uploadQuestionnaireResponse(_ response: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/QuestionnaireResponse") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: response)

        let (_, resp) = try await session.data(for: request)
        guard let httpResponse = resp as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
