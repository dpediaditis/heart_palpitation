//
//  HealthKitManager.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
//

import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    // MARK: - Fetch recent heart rate
    func fetchLatestQuantitySample(
        for identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        completion: @escaping (Double?) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            completion(nil)
            return
        }

        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: type,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            guard let quantitySample = samples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let value = quantitySample.quantity.doubleValue(for: unit)
            completion(value)
        }

        healthStore.execute(query)
    }
}
