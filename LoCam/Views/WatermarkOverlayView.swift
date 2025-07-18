//
//  WatermarkOverlayView.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import UIKit
import CoreLocation

// MARK: - Watermark Overlay View
class WatermarkOverlayView: UIView {
    
    private let dateLabel = UILabel()
    private let locationLabel = UILabel()
    private let customTextLabel = UILabel()
    private let containerView = UIView()
    private let stackView = UIStackView()
    
    private var settings = SettingsManager.WatermarkSettings()
    private var currentLocation: CLLocation?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        // Configure container
        containerView.backgroundColor = settings.backgroundColor
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Configure stack view
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)
        
        // Configure labels
        configureLabels()
        
        // Add labels to stack
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(locationLabel)
        stackView.addArrangedSubview(customTextLabel)
        
        setupConstraints()
        updateContent()
    }
    
    private func configureLabels() {
        [dateLabel, locationLabel, customTextLabel].forEach { label in
            label.font = UIFont.systemFont(ofSize: settings.fontSize)
            label.textColor = settings.textColor
            label.numberOfLines = 0
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        updatePosition()
    }
    
    private func updatePosition() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove existing constraints
        containerView.removeFromSuperview()
        addSubview(containerView)
        
        let margin: CGFloat = 20
        
        switch settings.position {
        case .topLeft:
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: margin),
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin)
            ])
        case .topRight:
            NSLayoutConstraint.activate([
                containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: margin),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin)
            ])
        case .bottomLeft:
            NSLayoutConstraint.activate([
                containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -margin),
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margin)
            ])
        case .bottomRight:
            NSLayoutConstraint.activate([
                containerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -margin),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -margin)
            ])
        }
    }
    
    func updateSettings(_ settings: SettingsManager.WatermarkSettings) {
        self.settings = settings
        configureLabels()
        containerView.backgroundColor = settings.backgroundColor
        updatePosition()
        updateContent()
    }
    
    func updateLocation(_ location: CLLocation?) {
        currentLocation = location
        updateContent()
    }
    
    private func updateContent() {
        // Update date
        if settings.showDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = formatter.string(from: Date())
            dateLabel.isHidden = false
        } else {
            dateLabel.isHidden = true
        }
        
        // Update location
        if settings.showLocation, let location = currentLocation {
            locationLabel.text = String(format: "%.6f, %.6f", location.coordinate.latitude, location.coordinate.longitude)
            locationLabel.isHidden = false
        } else {
            locationLabel.isHidden = true
        }
        
        // Update custom text
        if settings.showCustomText && !settings.customText.isEmpty {
            customTextLabel.text = settings.customText
            customTextLabel.isHidden = false
        } else {
            customTextLabel.isHidden = true
        }
        
        // Hide container if no content
        let hasContent = !dateLabel.isHidden || !locationLabel.isHidden || !customTextLabel.isHidden
        containerView.isHidden = !hasContent
    }
}