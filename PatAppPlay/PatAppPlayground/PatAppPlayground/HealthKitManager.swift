import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    // List of sample types you want to support
    let supportedTypes: [HKSampleType] = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        // Add more as needed
    ]
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare = Set(supportedTypes)
        let typesToRead = Set(supportedTypes)
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func isAuthorized(for type: HKSampleType) -> Bool {
        return healthStore.authorizationStatus(for: type) == .sharingAuthorized
    }
} 