//
//  MediaMetadata.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import Foundation
import CoreLocation

// MARK: - Location Data for Codable Support
struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date
    
    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.altitude = location.altitude
        self.timestamp = location.timestamp
    }
    
    func toCLLocation() -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: timestamp
        )
    }
}

// MARK: - Media Metadata Model
struct MediaMetadata: Codable {
    let id: UUID
    let timestamp: Date
    private let locationData: LocationData?
    let deviceInfo: DeviceInfo
    let digitalSignature: String
    let customWatermark: String?
    let isAnonymous: Bool
    
    var location: CLLocation? {
        return locationData?.toCLLocation()
    }
    
    init(id: UUID, timestamp: Date, location: CLLocation?, deviceInfo: DeviceInfo, digitalSignature: String, customWatermark: String?, isAnonymous: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.locationData = location != nil ? LocationData(from: location!) : nil
        self.deviceInfo = deviceInfo
        self.digitalSignature = digitalSignature
        self.customWatermark = customWatermark
        self.isAnonymous = isAnonymous
    }
    
    struct DeviceInfo: Codable {
        let model: String
        let systemVersion: String
        let appVersion: String
    }
}

// MARK: - Camera Mode Enum
enum CameraMode {
    case photo
    case video
    case stream
}