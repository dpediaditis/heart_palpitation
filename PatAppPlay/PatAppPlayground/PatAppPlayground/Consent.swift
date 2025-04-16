import Foundation
import HealthKit

struct Consent: Identifiable, Codable {
    enum Status: String, Codable {
        case pending
        case authorized
        case revoked
    }
    let id: UUID
    let dateGiven: Date
    let dataTypes: [HKSampleTypeIdentifier]
    let startDate: Date
    let endDate: Date
    var status: Status
    var bankIDTransactionID: String?
    
    init(dataTypes: [HKSampleTypeIdentifier], startDate: Date, endDate: Date, status: Status = .pending, bankIDTransactionID: String? = nil) {
        self.id = UUID()
        self.dateGiven = Date()
        self.dataTypes = dataTypes
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.bankIDTransactionID = bankIDTransactionID
    }
}

// Helper for HealthKit type identifiers
struct HKSampleTypeIdentifier: Codable, Hashable {
    let rawValue: String
    
    init(_ type: HKSampleType) {
        self.rawValue = type.identifier
    }
    
    var sampleType: HKSampleType? {
        HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: rawValue)) ??
        HKSampleType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: rawValue))
    }
} 