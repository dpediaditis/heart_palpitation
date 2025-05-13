import Foundation
import CryptoKit
import CommonCrypto

class LinkGenerator {
    private static let encryptionKey = "RLaC2trWndQEYtXF5VKzY5QcAmJCMQGg"
    private static let ivLength = 16
    
    static func generateLink(patientId: String, daysValid: Int, baseUrl: String = "http://localhost:3000") -> String {
        // Calculate expiration date
        let validUntil = Calendar.current.date(byAdding: .day, value: daysValid, to: Date())?.ISO8601Format() ?? ""
        
        // Encrypt the parameters
        let encryptedData = encryptParams(patientId: patientId, validUntil: validUntil)
        
        // Generate the complete URL
        return "\(baseUrl)?data=\(encryptedData)"
    }
    
    private static func encryptParams(patientId: String, validUntil: String) -> String {
        // Create the data to encrypt
        let data = [
            "patientId": patientId,
            "validUntil": validUntil
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let keyData = encryptionKey.data(using: .utf8) else {
            return ""
        }
        
        // Generate random IV
        var iv = [UInt8](repeating: 0, count: ivLength)
        _ = SecRandomCopyBytes(kSecRandomDefault, ivLength, &iv)
        
        // Create key
        var keyBytes = [UInt8](repeating: 0, count: kCCKeySizeAES256)
        keyData.copyBytes(to: &keyBytes, count: min(keyData.count, kCCKeySizeAES256))
        
        // Prepare data for encryption
        let dataLength = jsonData.count
        let bufferSize = dataLength + kCCBlockSizeAES128
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var numBytesEncrypted: size_t = 0
        
        // Perform encryption
        let cryptStatus = keyBytes.withUnsafeBytes { keyBytesPtr in
            iv.withUnsafeBytes { ivBytesPtr in
                jsonData.withUnsafeBytes { dataBytesPtr in
                    buffer.withUnsafeMutableBytes { bufferBytesPtr in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytesPtr.baseAddress,
                            kCCKeySizeAES256,
                            ivBytesPtr.baseAddress,
                            dataBytesPtr.baseAddress,
                            dataLength,
                            bufferBytesPtr.baseAddress,
                            bufferSize,
                            &numBytesEncrypted
                        )
                    }
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            return ""
        }
        
        // Get the encrypted data
        let encryptedData = buffer[..<numBytesEncrypted]
        
        // Encode IV and encrypted data separately
        let ivBase64 = Data(iv).base64EncodedString()
        let encryptedBase64 = Data(encryptedData).base64EncodedString()
        
        // Combine with colon separator
        let combined = "\(ivBase64):\(encryptedBase64)"
        
        // Make URL safe
        return combined
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
} 