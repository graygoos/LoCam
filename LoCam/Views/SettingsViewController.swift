//
//  SettingsViewController.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import UIKit
import Combine

class SettingsViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissSettings)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(saveSettings)
        )
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        SettingsManager.shared.$watermarkSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    @objc private func dismissSettings() {
        dismiss(animated: true)
    }
    
    @objc private func saveSettings() {
        // Settings are automatically saved through bindings
        dismiss(animated: true)
    }
}

// MARK: - Table View Data Source
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 // Watermark, Privacy, Emergency
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 6 // Watermark settings
        case 1: return 4 // Privacy settings
        case 2: return 3 // Emergency settings
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Watermark Settings"
        case 1: return "Privacy Settings"
        case 2: return "Emergency Settings"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        
        switch indexPath.section {
        case 0:
            configureWatermarkCell(cell, at: indexPath.row)
        case 1:
            configurePrivacyCell(cell, at: indexPath.row)
        case 2:
            configureEmergencyCell(cell, at: indexPath.row)
        default:
            break
        }
        
        return cell
    }
    
    private func configureWatermarkCell(_ cell: UITableViewCell, at row: Int) {
        let settings = SettingsManager.shared.watermarkSettings
        
        switch row {
        case 0:
            cell.textLabel?.text = "Show Date"
            let toggle = UISwitch()
            toggle.isOn = settings.showDate
            toggle.addTarget(self, action: #selector(watermarkDateToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 1:
            cell.textLabel?.text = "Show Location"
            let toggle = UISwitch()
            toggle.isOn = settings.showLocation
            toggle.addTarget(self, action: #selector(watermarkLocationToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 2:
            cell.textLabel?.text = "Show Custom Text"
            let toggle = UISwitch()
            toggle.isOn = settings.showCustomText
            toggle.addTarget(self, action: #selector(watermarkCustomTextToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 3:
            cell.textLabel?.text = "Custom Text"
            cell.detailTextLabel?.text = settings.customText.isEmpty ? "None" : settings.customText
            cell.accessoryType = .disclosureIndicator
        case 4:
            cell.textLabel?.text = "Position"
            cell.detailTextLabel?.text = settings.position.rawValue
            cell.accessoryType = .disclosureIndicator
        case 5:
            cell.textLabel?.text = "Font Size"
            cell.detailTextLabel?.text = "\(Int(settings.fontSize))pt"
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
    }
    
    private func configurePrivacyCell(_ cell: UITableViewCell, at row: Int) {
        let settings = SettingsManager.shared.privacySettings
        
        switch row {
        case 0:
            cell.textLabel?.text = "Anonymous Mode"
            let toggle = UISwitch()
            toggle.isOn = settings.anonymousMode
            toggle.addTarget(self, action: #selector(anonymousModeToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 1:
            cell.textLabel?.text = "Share Location"
            let toggle = UISwitch()
            toggle.isOn = settings.shareLocation
            toggle.addTarget(self, action: #selector(shareLocationToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 2:
            cell.textLabel?.text = "Auto Upload"
            let toggle = UISwitch()
            toggle.isOn = settings.autoUpload
            toggle.addTarget(self, action: #selector(autoUploadToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 3:
            cell.textLabel?.text = "Encrypt Files"
            let toggle = UISwitch()
            toggle.isOn = settings.encryptFiles
            toggle.addTarget(self, action: #selector(encryptFilesToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        default:
            break
        }
    }
    
    private func configureEmergencyCell(_ cell: UITableViewCell, at row: Int) {
        let settings = SettingsManager.shared.emergencySettings
        
        switch row {
        case 0:
            cell.textLabel?.text = "Panic Button"
            let toggle = UISwitch()
            toggle.isOn = settings.panicButtonEnabled
            toggle.addTarget(self, action: #selector(panicButtonToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 1:
            cell.textLabel?.text = "Auto Record"
            let toggle = UISwitch()
            toggle.isOn = settings.autoRecord
            toggle.addTarget(self, action: #selector(autoRecordToggled(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        case 2:
            cell.textLabel?.text = "Emergency Contacts"
            cell.detailTextLabel?.text = "\(settings.emergencyContacts.count)"
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
    }
    
    // MARK: - Toggle Actions
    @objc private func watermarkDateToggled(_ sender: UISwitch) {
        SettingsManager.shared.watermarkSettings.showDate = sender.isOn
    }
    
    @objc private func watermarkLocationToggled(_ sender: UISwitch) {
        SettingsManager.shared.watermarkSettings.showLocation = sender.isOn
    }
    
    @objc private func watermarkCustomTextToggled(_ sender: UISwitch) {
        SettingsManager.shared.watermarkSettings.showCustomText = sender.isOn
    }
    
    @objc private func anonymousModeToggled(_ sender: UISwitch) {
        SettingsManager.shared.privacySettings.anonymousMode = sender.isOn
    }
    
    @objc private func shareLocationToggled(_ sender: UISwitch) {
        SettingsManager.shared.privacySettings.shareLocation = sender.isOn
    }
    
    @objc private func autoUploadToggled(_ sender: UISwitch) {
        SettingsManager.shared.privacySettings.autoUpload = sender.isOn
    }
    
    @objc private func encryptFilesToggled(_ sender: UISwitch) {
        SettingsManager.shared.privacySettings.encryptFiles = sender.isOn
    }
    
    @objc private func panicButtonToggled(_ sender: UISwitch) {
        SettingsManager.shared.emergencySettings.panicButtonEnabled = sender.isOn
    }
    
    @objc private func autoRecordToggled(_ sender: UISwitch) {
        SettingsManager.shared.emergencySettings.autoRecord = sender.isOn
    }
}

// MARK: - Table View Delegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Handle detail view navigation for specific settings
        switch (indexPath.section, indexPath.row) {
        case (0, 3): // Custom text
            showCustomTextEditor()
        case (0, 4): // Position
            showPositionSelector()
        case (0, 5): // Font size
            showFontSizeSelector()
        case (2, 2): // Emergency contacts
            showEmergencyContactsEditor()
        default:
            break
        }
    }
    
    private func showCustomTextEditor() {
        let alert = UIAlertController(title: "Custom Text", message: "Enter custom watermark text", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = SettingsManager.shared.watermarkSettings.customText
            textField.placeholder = "Enter text..."
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text {
                SettingsManager.shared.watermarkSettings.customText = text
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showPositionSelector() {
        let alert = UIAlertController(title: "Watermark Position", message: "Select position", preferredStyle: .actionSheet)
        
        for position in SettingsManager.WatermarkPosition.allCases {
            alert.addAction(UIAlertAction(title: position.rawValue, style: .default) { _ in
                SettingsManager.shared.watermarkSettings.position = position
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showFontSizeSelector() {
        let alert = UIAlertController(title: "Font Size", message: "Select font size", preferredStyle: .actionSheet)
        
        let sizes: [CGFloat] = [12, 14, 16, 18, 20, 24, 28, 32]
        
        for size in sizes {
            alert.addAction(UIAlertAction(title: "\(Int(size))pt", style: .default) { _ in
                SettingsManager.shared.watermarkSettings.fontSize = size
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showEmergencyContactsEditor() {
        // This would show a more complex view controller for managing emergency contacts
        let alert = UIAlertController(title: "Emergency Contacts", message: "Feature coming soon", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}