//
//  SecurityManager.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import Foundation
import CryptoKit

// MARK: - Security Manager
class SecurityManager {
    static let shared = SecurityManager()
    private init() {}
    
    func generateDigitalSignature(for data: Data) -> String {
        let key = SymmetricKey(size: .bits256)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(signature).base64EncodedString()
    }
    
    func encryptData(_ data: Data) -> Data? {
        let key = SymmetricKey(size: .bits256)
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
}