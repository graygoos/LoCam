//
//  PhotoViewController.swift
//  LoCam
//
//  Created by Femi Aliu on 27/05/2024.
//

import UIKit
import AVFoundation
import Photos
import CoreLocation
import Combine

class PhotoViewController: UIViewController {
    
    // MARK: - Properties
    private var session: AVCaptureSession?
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    private let previewLayer = AVCaptureVideoPreviewLayer()
    
    private var currentMode: CameraMode = .photo
    private var isRecording = false
    private var recordingTimer: Timer?
    private var recordingDuration: TimeInterval = 0
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    private lazy var previewView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var controlsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var topControlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var bottomControlsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var modeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Photo", "Video", "Stream"])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        control.layer.cornerRadius = 8
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var shutterButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 40
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var flipCameraButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        button.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        button.layer.cornerRadius = 20
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape"), for: .normal)
        button.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        button.layer.cornerRadius = 20
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var emergencyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "exclamationmark.triangle"), for: .normal)
        button.backgroundColor = .systemRed.withAlphaComponent(0.8)
        button.layer.cornerRadius = 20
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var recordingIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 8
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var recordingLabel: UILabel = {
        let label = UILabel()
        label.text = "REC"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.textColor = .white
        label.font = .monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var watermarkOverlay: WatermarkOverlayView = {
        let overlay = WatermarkOverlayView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        return overlay
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
        setupLocationManager()
        setupBindings()
        setupNotifications()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = previewView.bounds
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .black
        
        // Add subviews
        view.addSubview(previewView)
        view.addSubview(controlsContainerView)
        view.addSubview(watermarkOverlay)
        
        // Setup preview layer
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer)
        
        // Setup controls
        setupControlsLayout()
        
        // Setup actions
        setupActions()
    }
    
    private func setupControlsLayout() {
        // Top controls
        topControlsStackView.addArrangedSubview(settingsButton)
        topControlsStackView.addArrangedSubview(createRecordingIndicatorStack())
        topControlsStackView.addArrangedSubview(emergencyButton)
        
        // Bottom controls
        bottomControlsStackView.addArrangedSubview(modeSegmentedControl)
        bottomControlsStackView.addArrangedSubview(createShutterControlsStack())
        
        controlsContainerView.addSubview(topControlsStackView)
        controlsContainerView.addSubview(bottomControlsStackView)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Preview view
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Controls container
            controlsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            controlsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlsContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Top controls
            topControlsStackView.topAnchor.constraint(equalTo: controlsContainerView.topAnchor, constant: 20),
            topControlsStackView.leadingAnchor.constraint(equalTo: controlsContainerView.leadingAnchor, constant: 20),
            topControlsStackView.trailingAnchor.constraint(equalTo: controlsContainerView.trailingAnchor, constant: -20),
            
            // Bottom controls
            bottomControlsStackView.bottomAnchor.constraint(equalTo: controlsContainerView.bottomAnchor, constant: -20),
            bottomControlsStackView.centerXAnchor.constraint(equalTo: controlsContainerView.centerXAnchor),
            bottomControlsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: controlsContainerView.leadingAnchor, constant: 20),
            bottomControlsStackView.trailingAnchor.constraint(lessThanOrEqualTo: controlsContainerView.trailingAnchor, constant: -20),
            
            // Watermark overlay
            watermarkOverlay.topAnchor.constraint(equalTo: previewView.topAnchor),
            watermarkOverlay.leadingAnchor.constraint(equalTo: previewView.leadingAnchor),
            watermarkOverlay.trailingAnchor.constraint(equalTo: previewView.trailingAnchor),
            watermarkOverlay.bottomAnchor.constraint(equalTo: previewView.bottomAnchor),
            
            // Button sizes
            shutterButton.widthAnchor.constraint(equalToConstant: 80),
            shutterButton.heightAnchor.constraint(equalToConstant: 80),
            
            flipCameraButton.widthAnchor.constraint(equalToConstant: 40),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 40),
            
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),
            
            emergencyButton.widthAnchor.constraint(equalToConstant: 40),
            emergencyButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    private func createRecordingIndicatorStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        
        recordingIndicator.addSubview(recordingLabel)
        NSLayoutConstraint.activate([
            recordingLabel.centerXAnchor.constraint(equalTo: recordingIndicator.centerXAnchor),
            recordingLabel.centerYAnchor.constraint(equalTo: recordingIndicator.centerYAnchor),
            recordingIndicator.widthAnchor.constraint(equalToConstant: 40),
            recordingIndicator.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        stack.addArrangedSubview(recordingIndicator)
        stack.addArrangedSubview(timerLabel)
        
        return stack
    }
    
    private func createShutterControlsStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 40
        stack.alignment = .center
        
        stack.addArrangedSubview(UIView()) // Spacer
        stack.addArrangedSubview(shutterButton)
        stack.addArrangedSubview(flipCameraButton)
        
        return stack
    }
    
    private func setupActions() {
        shutterButton.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
        flipCameraButton.addTarget(self, action: #selector(flipCameraButtonTapped), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        emergencyButton.addTarget(self, action: #selector(emergencyButtonTapped), for: .touchUpInside)
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        checkCameraPermissions()
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCaptureSession()
                    }
                }
            }
        default:
            showPermissionDeniedAlert()
        }
    }
    
    private func setupCaptureSession() {
        session = AVCaptureSession()
        session?.sessionPreset = .high
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        if session?.canAddInput(videoInput) == true {
            session?.addInput(videoInput)
        }
        
        // Add audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            return
        }
        
        if session?.canAddInput(audioInput) == true {
            session?.addInput(audioInput)
        }
        
        // Add outputs
        if session?.canAddOutput(photoOutput) == true {
            session?.addOutput(photoOutput)
        }
        
        if session?.canAddOutput(videoOutput) == true {
            session?.addOutput(videoOutput)
        }
        
        // Setup preview layer
        previewLayer.session = session
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session?.startRunning()
        }
    }
    
    // MARK: - Location Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Bindings and Notifications
    private func setupBindings() {
        SettingsManager.shared.$watermarkSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.watermarkOverlay.updateSettings(settings)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(emergencyTriggered),
            name: .emergencyTriggered,
            object: nil
        )
    }
    
    // MARK: - Actions
    @objc private func shutterButtonTapped() {
        switch currentMode {
        case .photo:
            capturePhoto()
        case .video:
            if isRecording {
                stopVideoRecording()
            } else {
                startVideoRecording()
            }
        case .stream:
            // Implement streaming
            break
        }
    }
    
    @objc private func flipCameraButtonTapped() {
        guard let session = session else { return }
        
        session.beginConfiguration()
        
        let currentInput = session.inputs.first as? AVCaptureDeviceInput
        let newCameraPosition: AVCaptureDevice.Position = currentInput?.device.position == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            session.commitConfiguration()
            return
        }
        
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        
        session.commitConfiguration()
    }
    
    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    @objc private func emergencyButtonTapped() {
        EmergencyManager.shared.triggerEmergencyMode(location: currentLocation)
    }
    
    @objc private func modeChanged() {
        let modes: [CameraMode] = [.photo, .video, .stream]
        currentMode = modes[modeSegmentedControl.selectedSegmentIndex]
        updateUIForMode()
    }
    
    @objc private func emergencyTriggered() {
        // Auto-start recording in emergency mode
        if currentMode != .video {
            currentMode = .video
            modeSegmentedControl.selectedSegmentIndex = 1
            updateUIForMode()
        }
        
        if !isRecording {
            startVideoRecording()
        }
    }
    
    // MARK: - Camera Operations
    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func startVideoRecording() {
        guard !isRecording else { return }
        
        let outputURL = createVideoOutputURL()
        videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        isRecording = true
        recordingDuration = 0
        updateRecordingUI()
        startRecordingTimer()
    }
    
    private func stopVideoRecording() {
        guard isRecording else { return }
        
        videoOutput.stopRecording()
        isRecording = false
        stopRecordingTimer()
        updateRecordingUI()
    }
    
    private func createVideoOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("\(UUID().uuidString).mov")
        return outputURL
    }
    
    // MARK: - UI Updates
    private func updateUIForMode() {
        switch currentMode {
        case .photo:
            shutterButton.backgroundColor = .white
            shutterButton.layer.borderColor = UIColor.systemBlue.cgColor
        case .video:
            shutterButton.backgroundColor = isRecording ? .systemRed : .white
            shutterButton.layer.borderColor = UIColor.systemRed.cgColor
        case .stream:
            shutterButton.backgroundColor = .systemPurple
            shutterButton.layer.borderColor = UIColor.systemPurple.cgColor
        }
    }
    
    private func updateRecordingUI() {
        recordingIndicator.isHidden = !isRecording
        timerLabel.isHidden = !isRecording
        
        if isRecording {
            // Add blinking animation to recording indicator
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.duration = 0.5
            animation.repeatCount = .infinity
            animation.autoreverses = true
            recordingIndicator.layer.add(animation, forKey: "blink")
        } else {
            recordingIndicator.layer.removeAllAnimations()
        }
        
        updateUIForMode()
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRecordingTimer()
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingTimer() {
        recordingDuration += 1
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to use this app.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - Extensions
extension PhotoViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Process and save the image with watermark
        processAndSaveImage(image)
    }
    
    private func processAndSaveImage(_ image: UIImage) {
        // Add watermark
        let watermarkedImage = addWatermarkToImage(image)
        
        // Create metadata
        let metadata = createMediaMetadata()
        
        // Save to photo library
        saveImageToPhotoLibrary(watermarkedImage, metadata: metadata)
        
        // Upload to cloud if enabled
        if SettingsManager.shared.privacySettings.autoUpload {
            // Implement cloud upload
        }
    }
}

extension PhotoViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("Video recording error: \(error!)")
            return
        }
        
        // Process and save the video
        processAndSaveVideo(at: outputFileURL)
    }
    
    private func processAndSaveVideo(at url: URL) {
        // Add watermark to video
        addWatermarkToVideo(at: url) { [weak self] processedURL in
            guard let self = self else { return }
            
            // Create metadata
            let metadata = self.createMediaMetadata()
            
            // Save to photo library
            self.saveVideoToPhotoLibrary(processedURL, metadata: metadata)
            
            // Upload to cloud if enabled
            if SettingsManager.shared.privacySettings.autoUpload {
                // Implement cloud upload
            }
        }
    }
}

extension PhotoViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        watermarkOverlay.updateLocation(currentLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}

// MARK: - Helper Methods
extension PhotoViewController {
    private func createMediaMetadata() -> MediaMetadata {
        let deviceInfo = MediaMetadata.DeviceInfo(
            model: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        )
        
        let metadata = MediaMetadata(
            id: UUID(),
            timestamp: Date(),
            location: currentLocation,
            deviceInfo: deviceInfo,
            digitalSignature: "",
            customWatermark: SettingsManager.shared.watermarkSettings.customText,
            isAnonymous: SettingsManager.shared.privacySettings.anonymousMode
        )
        
        return metadata
    }
    
    private func addWatermarkToImage(_ image: UIImage) -> UIImage {
        // Implementation for adding watermark to image
        return WatermarkProcessor.shared.addWatermark(to: image,
                                                      location: currentLocation,
                                                      settings: SettingsManager.shared.watermarkSettings)
    }
    
    private func addWatermarkToVideo(at url: URL, completion: @escaping (URL) -> Void) {
        // Implementation for adding watermark to video
        WatermarkProcessor.shared.addWatermark(to: url,
                                               location: currentLocation,
                                               settings: SettingsManager.shared.watermarkSettings,
                                               completion: completion)
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage, metadata: MediaMetadata) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.creationDate = metadata.timestamp
            if !metadata.isAnonymous {
                request.location = metadata.location
            }
        }) { success, error in
            if !success {
                print("Failed to save image: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func saveVideoToPhotoLibrary(_ url: URL, metadata: MediaMetadata) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            request?.creationDate = metadata.timestamp
            if !metadata.isAnonymous {
                request?.location = metadata.location
            }
        }) { success, error in
            if !success {
                print("Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}
