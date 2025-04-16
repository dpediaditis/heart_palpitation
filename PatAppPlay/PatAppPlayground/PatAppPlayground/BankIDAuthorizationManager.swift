import Foundation

class BankIDAuthorizationManager {
    static let shared = BankIDAuthorizationManager()
    
    // Simulate BankID flow
    func authorize(completion: @escaping (Bool, String?) -> Void) {
        // TODO: Integrate real BankID flow here
        // For now, simulate success after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(true, "simulated-bankid-transaction-id")
        }
    }
} 