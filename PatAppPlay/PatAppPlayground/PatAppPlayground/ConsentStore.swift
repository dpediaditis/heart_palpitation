import Foundation
import HealthKit

extension Notification.Name {
    static let consentChanged = Notification.Name("consentChanged")
}

class ConsentStore: ObservableObject {
    static let shared = ConsentStore()
    private let dataSyncService = DataSyncService.shared
    
    @Published private(set) var currentConsent: Consent?
    
    private init() {
        loadConsent()
    }
    
    func saveConsent(_ consent: Consent) {
        currentConsent = consent
        UserDefaults.standard.set(try? JSONEncoder().encode(consent), forKey: "currentConsent")
        NotificationCenter.default.post(name: .consentChanged, object: nil)
        
        // Start data synchronization
        DataSyncService.shared.startSync(for: consent)
    }
    
    func withdrawConsent() {
        currentConsent = nil
        UserDefaults.standard.removeObject(forKey: "currentConsent")
    }
    
    private func loadConsent() {
        if let data = UserDefaults.standard.data(forKey: "currentConsent"),
           let consent = try? JSONDecoder().decode(Consent.self, from: data) {
            currentConsent = consent
        }
    }
} 