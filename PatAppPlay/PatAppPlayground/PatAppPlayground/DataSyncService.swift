import Foundation
import HealthKit
import UIKit

class DataSyncService {
    static let shared = DataSyncService()
    private let backendURL = URL(string: "http://localhost:3000/api/health-data")!
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {
        // Start periodic syncing when the app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        syncTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 App became active - checking for sync")
        // Sync immediately when app becomes active
        if let consent = ConsentStore.shared.currentConsent, consent.isActive {
            print("🔄 Starting sync due to app activation")
            startSync(for: consent)
        } else {
            print("⏹ No active consent - skipping sync")
        }
    }
    
    func startSync(for consent: Consent) {
        print("🔄 Starting sync for consent with \(consent.dataTypes.count) data types")
        
        // Start a background task to ensure sync completes
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("⚠️ Background task expired")
            self?.endBackgroundTask()
        }
        
        // Sync each data type
        for dataType in consent.dataTypes {
            print("📊 Syncing data type: \(dataType.rawValue)")
            syncDataType(dataType, for: consent)
        }
        
        // Set up periodic syncing if consent is active
        if consent.isActive {
            print("⏰ Setting up periodic sync (every 24 hours)")
            setupPeriodicSync()
        } else {
            print("⏹ Stopping periodic sync - consent is not active")
            syncTimer?.invalidate()
            syncTimer = nil
        }
    }
    
    private func setupPeriodicSync() {
        // Invalidate existing timer if any
        syncTimer?.invalidate()
        
        // Create new timer for periodic syncing
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            if let consent = ConsentStore.shared.currentConsent, consent.isActive {
                self?.startSync(for: consent)
            } else {
                self?.syncTimer?.invalidate()
                self?.syncTimer = nil
            }
        }
    }
    
    private func syncDataType(_ dataType: HKSampleTypeIdentifier, for consent: Consent) {
        print("🔍 Fetching samples for \(dataType.rawValue) from \(consent.startDate) to \(consent.endDate)")
        
        // Convert HKSampleTypeIdentifier to HKQuantityTypeIdentifier
        let quantityTypeIdentifier = HKQuantityTypeIdentifier(rawValue: dataType.rawValue)
        guard let sampleType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) else {
            print("❌ Failed to create quantity type for \(dataType.rawValue)")
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: consent.startDate,
            end: consent.endDate,
            options: .strictStartDate
        )
        
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { [weak self] _, samples, error in
            if let error = error {
                print("❌ Error fetching samples for \(dataType.rawValue): \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                print("❌ No samples found for \(dataType.rawValue)")
                return
            }
            
            print("✅ Found \(samples.count) samples for \(dataType.rawValue)")
            
            for sample in samples {
                self?.sendSampleToBackend(sample, dataType: dataType)
            }
        }
        
        HKHealthStore().execute(query)
    }
    
    private func sendSampleToBackend(_ sample: HKQuantitySample, dataType: HKSampleTypeIdentifier) {
        let value = sample.quantity.doubleValue(for: HKUnit.count())
        let timestamp = sample.startDate.formatted(.iso8601)
        let deviceSource = sample.device?.name ?? "Unknown Device"
        
        print("📤 Sending sample to backend - Type: \(dataType.rawValue), Value: \(value), Time: \(timestamp)")
        
        let data: [String: Any] = [
            "userId": UserDefaults.standard.string(forKey: "userId") ?? "unknown",
            "dataType": dataType.rawValue,
            "value": value,
            "timestamp": timestamp,
            "deviceSource": deviceSource
        ]
        
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            print("❌ Error serializing data: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            if let error = error {
                print("❌ Error sending data to backend: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Successfully sent sample to backend")
                } else {
                    print("❌ Backend returned error status: \(httpResponse.statusCode)")
                }
            }
            
            // End background task if this was the last request
            self?.endBackgroundTask()
        }
        
        task.resume()
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
} 