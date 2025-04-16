import Foundation

class ConsentStore: ObservableObject {
    @Published private(set) var consents: [Consent] = []
    private let storageKey = "consents"
    
    init() {
        load()
    }
    
    func addConsent(_ consent: Consent) {
        consents.append(consent)
        save()
    }
    
    func updateConsent(_ consent: Consent) {
        if let idx = consents.firstIndex(where: { $0.id == consent.id }) {
            consents[idx] = consent
            save()
        }
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(consents) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Consent].self, from: data) {
            consents = decoded
        }
    }
} 