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

class PhotoViewController: UIViewController, CLLocationManagerDelegate {
    
    // capture session
    var session: AVCaptureSession?
    // photo output
    let photoOutput = AVCapturePhotoOutput()
    // video output
    let videoOutput = AVCaptureMovieFileOutput()
    // video preview
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    // Buttons
    var photoButton: UIButton = {
        let buttonConfig = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular, scale: .large)
        let photoButton = UIImage(systemName: "square.inset.filled", withConfiguration: buttonConfig)
        let button = UIButton()
        
        button.tintColor = .white
        button.setImage(photoButton, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        
        return button
    }()
    
    let flipCameraButton : UIButton = {
        let button = UIButton()
        let image = UIImage(named: "flip-2")?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let startVideoButton: UIButton = {
        var buttonConfig = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular, scale: .large)
        buttonConfig = buttonConfig.applying(UIImage.SymbolConfiguration(paletteColors: [UIColor.systemRed, UIColor.white]))
        let startVideo = UIImage(systemName: "square.inset.filled", withConfiguration: buttonConfig)
        let button = UIButton()
        
        button.setImage(startVideo, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        
        return button
    }()
    
    private let stopVideoButton: UIButton = {
        var buttonConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular, scale: .large)
        buttonConfig = buttonConfig.applying(UIImage.SymbolConfiguration(paletteColors: [UIColor.systemRed, UIColor.white]))
        let stopVideo = UIImage(systemName: "square.fill", withConfiguration: buttonConfig)
        let button = UIButton()
        
        button.setImage(stopVideo, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        
        return button
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Photo", "Video"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    // Timer label
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    // Date label
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Location label
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private var timer: Timer?
    private var recordingDuration: TimeInterval = 0
    
    // Location Manager
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        
        //        shutterButton.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height - 100)
        updateShutterButtonPosition()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.addSublayer(previewLayer)
        view.backgroundColor = .cyan
        view.addSubview(segmentedControl)
        view.addSubview(photoButton)
        view.addSubview(flipCameraButton)
        view.addSubview(timerLabel)
        view.addSubview(dateLabel)
        view.addSubview(locationLabel)
        
        segmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        flipCameraButton.addTarget(self, action: #selector(didTapFlipCameraButton), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150),
            flipCameraButton.widthAnchor.constraint(equalToConstant: 50),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 50),
            flipCameraButton.centerYAnchor.constraint(equalTo: photoButton.centerYAnchor),
            flipCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            dateLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10)
        ])
        
        checkCameraPermissions()
        
        photoButton.addTarget(self, action: #selector(didTapShutterButton), for: .touchUpInside)
        
        // Location manager setup
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        startUpdatingDateAndLocation()
    }
    
    private func updateShutterButtonPosition() {
        photoButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 100)
    }
    
    @objc private func modeChanged() {
        if segmentedControl.selectedSegmentIndex == 0 {
            // Photo mode
            photoButton.setImage(UIImage(systemName: "square.inset.filled", withConfiguration: UIImage.SymbolConfiguration(pointSize: 120, weight: .regular, scale: .large)), for: .normal)
        } else {
            // Video mode
            photoButton.setImage(startVideoButton.imageView?.image, for: .normal)
        }
    }
    
    @objc private func didTapShutterButton() {
        if segmentedControl.selectedSegmentIndex == 0 {
            // Photo mode
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        } else {
            // Video mode
            segmentedControl.isHidden = true
            flipCameraButton.isHidden = true
            if videoOutput.isRecording {
                videoOutput.stopRecording()
                timer?.invalidate()
                timerLabel.isHidden = true
                segmentedControl.isHidden = false
                flipCameraButton.isHidden = false
            } else {
                guard let connection = videoOutput.connection(with: .video) else { return }
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = currentVideoOrientation()
                }
                let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
                videoOutput.startRecording(to: outputURL, recordingDelegate: self)
                recordingDuration = 0
                timerLabel.isHidden = false
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    self?.updateTimerLabel()
                }
            }
        }
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .landscapeRight:
            return .landscapeLeft
        case .landscapeLeft:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    @objc private func didTapFlipCameraButton() {
        guard let session = session else { return }
        
        DispatchQueue.global(qos: .background).async {
            session.beginConfiguration()
            
            guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else {
                session.commitConfiguration()
                return
            }
            
            session.removeInput(currentInput)
            
            let newCamera: AVCaptureDevice
            if currentInput.device.position == .back {
                newCamera = self.camera(with: .front) ?? currentInput.device
            } else {
                newCamera = self.camera(with: .back) ?? currentInput.device
            }
            
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if session.canAddInput(newInput) {
                    session.addInput(newInput)
                } else {
                    session.addInput(currentInput)
                }
            } catch {
                session.addInput(currentInput)
                print("Error switching cameras: \(error)")
            }
            
            session.commitConfiguration()
        }
    }
    
    private func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices
        return devices.first(where: { $0.position == position })
    }
    
    
    private func updateTimerLabel() {
        recordingDuration += 1
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // request permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    return
                }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera(position: AVCaptureDevice.Position = .back) {
        let session = AVCaptureSession()
        guard let device = camera(with: position) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            // Add audio input
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
            }
            
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
            }
            
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.session = session
            
            // Start the session on a background thread
            DispatchQueue.global(qos: .background).async {
                session.startRunning()
            }
            
            self.session = session
        } catch {
            print(error)
        }
    }
    
    @objc private func didTakePhoto() {
        //        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        if videoOutput.isRecording {
            videoOutput.stopRecording()
        } else {
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    private func startUpdatingDateAndLocation() {
        // Update the date label every second
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDateLabel()
        }
        
        // Update the location label as needed (assuming you have a method to get location updates)
        updateLocationLabel()
    }
    
    private func updateDateLabel() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateLabel.text = formatter.string(from: date)
    }
    
    private func updateLocationLabel() {
        guard let currentLocation = currentLocation else {
            locationLabel.text = "Location: Unknown"
            return
        }
        let latitude = currentLocation.coordinate.latitude
        let longitude = currentLocation.coordinate.longitude
        locationLabel.text = String(format: "Location: %.4f, %.4f", latitude, longitude)
    }
    
    
    // MARK: - Watermark Functions
    private func addWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        return renderer.image { context in
            image.draw(at: .zero)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40),
                .foregroundColor: UIColor.red
            ]
            
            let locationString = currentLocation != nil ? "\(currentLocation!.coordinate.latitude), \(currentLocation!.coordinate.longitude)" : "Unknown Location"
            let watermark = "\(dateString)\n\(locationString)"
            
            let attributedString = NSAttributedString(string: watermark, attributes: attributes)
            attributedString.draw(at: CGPoint(x: 20, y: 20))
        }
    }
    
    private func addWatermarkToVideo(at url: URL, completion: @escaping (URL) -> Void) {
        let asset = AVAsset(url: url)
        let composition = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            completion(url) // In case of failure, return the original video URL
            return
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoTrack.naturalSize
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        let size = videoTrack.naturalSize
        
        // Create watermark layer
        let watermarkLayer = CALayer()
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: date)
        
        let locationString = currentLocation != nil ? "\(currentLocation!.coordinate.latitude), \(currentLocation!.coordinate.longitude)" : "Unknown Location"
        let watermarkText = "\(dateString)\n\(locationString)"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40),
            .foregroundColor: UIColor.red
        ]
        
        let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
        let textLayer = CATextLayer()
        textLayer.string = attributedString
        textLayer.shouldRasterize = true
        textLayer.rasterizationScale = UIScreen.main.scale
        textLayer.frame = CGRect(x: 20, y: 20, width: size.width - 40, height: 100)
        
        watermarkLayer.addSublayer(textLayer)
        watermarkLayer.frame = CGRect(origin: .zero, size: size)
        watermarkLayer.masksToBounds = true
        
        // Create parent layer
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: size)
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: size)
        overlayLayer.addSublayer(videoLayer)
        overlayLayer.addSublayer(watermarkLayer)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: overlayLayer)
        
        // Export the video with watermark
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.videoComposition = videoComposition
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        exportSession?.outputURL = outputURL
        exportSession?.outputFileType = .mov
        exportSession?.exportAsynchronously {
            switch exportSession?.status {
            case .completed:
                completion(outputURL)
            case .failed, .cancelled:
                completion(url) // Return the original URL in case of failure
            default:
                break
            }
        }
    }
    
    // MARK: - Save to Photo Library
    private func saveImageToPhotoLibrary(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.creationDate = Date()
            if let location = self.currentLocation {
                request.location = location
            }
        }, completionHandler: { success, error in
            if !success {
                print("Error saving photo: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
    }
    
    private func saveVideoToPhotoLibrary(videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            request?.creationDate = Date()
            if let location = self.currentLocation {
                request?.location = location
            }
        }, completionHandler: { success, error in
            if !success {
                print("Error saving video: \(error?.localizedDescription ?? "Unknown error")")
            }
        })
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            updateLocationLabel()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

extension PhotoViewController: AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    // MARK: - Photo Capture Delegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            return
        }
        
        let watermarkedImage = addWatermark(to: image)
        
        saveImageToPhotoLibrary(image: watermarkedImage)
    }
    
    // MARK: - Video Capture Delegate
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("Error recording movie: \(error!)")
            return
        }
        
        addWatermarkToVideo(at: outputFileURL) { [weak self] urlWithWatermark in
            guard let self = self else { return }
            self.saveVideoToPhotoLibrary(videoURL: urlWithWatermark)
        }
    }
}
