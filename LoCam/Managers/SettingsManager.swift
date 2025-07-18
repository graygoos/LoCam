//
//  SettingsManager.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import Foundation
import UIKit
import Combine

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    private init() {}
    
    @Published var watermarkSettings = WatermarkSettings()
    @Published var privacySettings = PrivacySettings()
    @Published var emergencySettings = EmergencySettings()
    
    struct WatermarkSettings: Codable {
        var showDate: Bool = true
        var showLocation: Bool = true
        var showCustomText: Bool = false
        var customText: String = ""
        var position: WatermarkPosition = .topLeft
        var fontSize: CGFloat = 16
        private var _textColor: CodableColor = CodableColor(.white)
        private var _backgroundColor: CodableColor = CodableColor(.black.withAlphaComponent(0.7))
        
        var textColor: UIColor {
            get { _textColor.color }
            set { _textColor = CodableColor(newValue) }
        }
        
        var backgroundColor: UIColor {
            get { _backgroundColor.color }
            set { _backgroundColor = CodableColor(newValue) }
        }
        
        enum CodingKeys: String, CodingKey {
            case showDate, showLocation, showCustomText, customText, position, fontSize
            case _textColor = "textColor"
            case _backgroundColor = "backgroundColor"
        }
    }
    
    struct PrivacySettings: Codable {
        var anonymousMode: Bool = false
        var shareLocation: Bool = true
        var autoUpload: Bool = false
        var encryptFiles: Bool = true
    }
    
    struct EmergencySettings: Codable {
        var emergencyContacts: [String] = []
        var panicButtonEnabled: Bool = true
        var autoRecord: Bool = true
        var autoUpload: Bool = true
    }
    
    enum WatermarkPosition: String, CaseIterable, Codable {
        case topLeft = "Top Left"
        case topRight = "Top Right"
        case bottomLeft = "Bottom Left"
        case bottomRight = "Bottom Right"
    }
}

// MARK: - CodableColor Wrapper
struct CodableColor: Codable {
    let color: UIColor
    
    init(_ color: UIColor) {
        self.color = color
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let colorData = [red, green, blue, alpha]
        try container.encode(colorData)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let colorData = try container.decode([CGFloat].self)
        self.color = UIColor(red: colorData[0], green: colorData[1], blue: colorData[2], alpha: colorData[3])
    }
}