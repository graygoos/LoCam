//
//  EmergencyManager.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import Foundation
import CoreLocation

// MARK: - Emergency Manager
class EmergencyManager {
    static let shared = EmergencyManager()
    private init() {}
    
    func triggerEmergencyMode(location: CLLocation?) {
        // Start recording
        NotificationCenter.default.post(name: .emergencyTriggered, object: nil)
        
        // Send alert to emergency contacts
        sendEmergencyAlert(location: location)
        
        // Auto-upload current recording
        // Implementation here
    }
    
    private func sendEmergencyAlert(location: CLLocation?) {
        // Implementation for sending emergency alerts
        print("Emergency alert sent to contacts")
    }
}

extension Notification.Name {
    static let emergencyTriggered = Notification.Name("emergencyTriggered")
}