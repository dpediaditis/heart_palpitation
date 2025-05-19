import Foundation
import HealthKit
import SwiftUI

/// A service to handle FHIR-formatted data export and API communication using FHIR Bundles
class FHIRDataService: ObservableObject {
    @Published var isUploading = false
    @Published var lastSyncDate: Date? {
        didSet {
            if let date = lastSyncDate {
                UserDefaults.standard.set(date, forKey: "lastSyncDate")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastSyncDate")
            }
        }
    }

    private let baseURL: String
    private let session: URLSession
    private let healthStore = HKHealthStore()

    init(baseURL: String = "https://gw.interop.community/hp2025stan/open") {
        self.baseURL = baseURL
        self.session = URLSession.shared
        // Load last sync date from UserDefaults
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    /// Create a basic Patient resource (once)
    func createPatient() async throws {
        let patient: [String: Any] = [
            "resourceType": "Patient",
            "id": AppConfig.patientId,
            "name": [[
                "given": ["Phone"],
                "family": "Anton"
            ]],
            "gender" : "male",
            "birthDate" : "1999-06-23"
        ]
        let url = URL(string: "\(baseURL)/\(AppConfig.patientReference)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: patient)

        let (_, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("👤 Patient Status: \(httpResponse.statusCode)")
        }
    }
    
    /// Posts a completed QuestionnaireResponse payload to the FHIR server
    func uploadQuestionnaireResponse(_ response: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/QuestionnaireResponse") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: response)
        request.httpBody = jsonData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Syncs all health data and returns the timestamp of the sync
    func syncHealthData(
        hrSamples: [HKQuantitySample],
        restingSamples: [HKQuantitySample],
        oxygenSamples: [HKQuantitySample],
        stepSamples: [HKQuantitySample],
        energySamples: [HKQuantitySample],
        exerciseSamples: [HKQuantitySample],
        standSamples: [HKQuantitySample],
        glucoseSamples: [HKQuantitySample],
        ecgSamples: [HKElectrocardiogram]
    ) async throws -> Date {
        // Store current timestamp before sync
        let syncTimestamp = Date()
        
        // Perform the sync
        try await uploadAllHealthData(
            hrSamples: hrSamples,
            restingSamples: restingSamples,
            oxygenSamples: oxygenSamples,
            stepSamples: stepSamples,
            energySamples: energySamples,
            exerciseSamples: exerciseSamples,
            standSamples: standSamples,
            glucoseSamples: glucoseSamples,
            ecgSamples: ecgSamples
        )
        
        // Update lastSyncDate after successful sync
        await MainActor.run {
            self.lastSyncDate = syncTimestamp
        }
        
        return syncTimestamp
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
        let patientRef = FHIRReference(reference: AppConfig.patientReference)

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
                id: nil,
                status: "final",
                code: FHIRCodeableConcept(coding: [
                    FHIRCoding(system: "http://loinc.org", code: loinc, display: display)
                ]),
                subject: patientRef,
                effectiveDateTime: sample.startDate.iso8601String(),
                valueQuantity: FHIRQuantity(value: value, unit: fhirUnit, system: "http://unitsofmeasure.org", code: fhirCode)
            )
            entries.append(
                FHIRBundleEntry(
                    request: FHIRBundleRequest(method: "POST", url: "Observation"),
                    resource: obs,
                    fullUrl: nil,
                    search: nil
                )
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
                id: nil,
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
                FHIRBundleEntry(
                    request: FHIRBundleRequest(method: "POST", url: "Observation"),
                    resource: ecgObs,
                    fullUrl: nil,
                    search: nil
                )
            )
        }

        // Build and POST transaction Bundle
        let bundle = FHIRBundle(
            resourceType: "Bundle",
            type: "transaction",
            entry: entries
        )
        let bundleURL = URL(string: baseURL)!
        var bundleReq = URLRequest(url: bundleURL)
        bundleReq.httpMethod = "POST"
        bundleReq.addValue("application/fhir+json", forHTTPHeaderField: "Content-Type")
        bundleReq.httpBody = try JSONEncoder().encode(bundle)

        let (_, response) = try await session.data(for: bundleReq)
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Bundle POST status: \(httpResponse.statusCode)")
        }
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        DispatchQueue.main.async { self.lastSyncDate = Date() }
    }

    func uploadECGData(_ ecgData: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/Observation") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try JSONSerialization.data(withJSONObject: ecgData)
        request.httpBody = jsonData
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func fetchRecentECGMeasurements() async throws -> [(id: String, effectiveDateTime: String)] {
        guard let url = URL(string: "\(baseURL)/Observation?subject=\(AppConfig.patientReference)&code=http://loinc.org|131328-4&_sort=-date&_count=5&_elements=id,effectiveDateTime") else {
            throw URLError(.badURL)
        }
        
        print("\n🔍 Fetching ECG measurements from URL: \(url)")
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        print("👤 ECG Measurements fetched. HTTP Status: \(httpResponse.statusCode)")
        
        // Print raw response data
        if let jsonString = String(data: data, encoding: .utf8) {
            print("\n📦 Raw FHIR Response:")
            print("----------------------------------------")
            print(jsonString)
            print("----------------------------------------")
        }
        
        do {
            let bundle = try JSONDecoder().decode(FHIRBundle.self, from: data)
            print("\n📊 Decoded Bundle:")
            print("  - Resource Type: \(bundle.resourceType)")
            print("  - Type: \(bundle.type)")
            print("  - Total Entries: \(bundle.entry?.count ?? 0)")
            
            let results = bundle.entry?.compactMap { entry -> (id: String, effectiveDateTime: String)? in
                print("\n🔍 Processing Entry:")
                print("  - Full URL: \(entry.fullUrl ?? "nil")")
                print("  - Search Mode: \(entry.search?.mode ?? "nil")")
                
                guard let observation = entry.resource as? FHIRObservation else {
                    print("  ❌ Failed to cast resource to FHIRObservation")
                    return nil
                }
                
                print("  ✅ Successfully decoded observation:")
                print("    - ID: \(observation.id ?? "nil")")
                print("    - Status: \(observation.status ?? "nil")")
                print("    - Effective Date: \(observation.effectiveDateTime)")
                
                return (id: observation.id ?? "", effectiveDateTime: observation.effectiveDateTime)
            } ?? []
            
            print("\n📋 Final Results:")
            print("  - Total valid observations: \(results.count)")
            for (index, result) in results.enumerated() {
                print("    \(index + 1). ID: \(result.id), Date: \(result.effectiveDateTime)")
            }
            
            return results
        } catch {
            print("\n❌ Failed to decode FHIR response:")
            print("  Error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("  Missing key: \(key.stringValue)")
                    print("  Context: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("  Type mismatch: expected \(type)")
                    print("  Context: \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("  Value not found: expected \(type)")
                    print("  Context: \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("  Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("  Unknown decoding error")
                }
            }
            throw error
        }
    }
}

// MARK: - FHIR Models

enum FHIRError: Error { case uploadFailed }

struct FHIRObservation: Codable {
    let resourceType = "Observation"
    let id: String?
    let status: String?
    let code: FHIRCodeableConcept?
    let subject: FHIRReference?
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

struct FHIRBundle: Codable {
    let resourceType: String
    let type: String
    let entry: [FHIRBundleEntry]?
}

struct FHIRBundleEntry: Codable {
    let request: FHIRBundleRequest?
    let resource: FHIRObservation
    let fullUrl: String?
    let search: FHIRBundleSearch?

    enum CodingKeys: String, CodingKey {
        case request, resource, fullUrl, search
    }
}

struct FHIRBundleSearch: Codable {
    let mode: String
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

