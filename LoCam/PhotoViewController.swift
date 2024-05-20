
//
//  ViewController.swift
//  CameraExperimentation
//
//  Created by Femi Aliu on 06/05/2024.
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
            if videoOutput.isRecording {
                videoOutput.stopRecording()
                timer?.invalidate()
                timerLabel.isHidden = true
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
    /*
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
            DispatchQueue.main.async {
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
    }
    */
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














/*
import AVFoundation
//import CoreLocation
import Photos
import UIKit


class PhotoViewController: UIViewController, CLLocationManagerDelegate {

    // Capture Session
    var session: AVCaptureSession?
    // Photo Output
    let photoOutput = AVCapturePhotoOutput()
    // Video Output
    var videoFileOutput: AVCaptureMovieFileOutput?
    // Video Preview
    var previewLayer = AVCaptureVideoPreviewLayer()
    // Camera Button
    let photoCameraButton = LCButton()
    let videoCameraButton = LCButton()
    let flipCamera = LCButton()
    
    var videoDeviceInput: AVCaptureDeviceInput!
    
    var photoInput: AVCaptureDeviceInput?
    
    var rearCameraOn = true
    
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var backCameraInput: AVCaptureInput!
    var frontCameraInput: AVCaptureInput!
    var currentDevice: AVCaptureDevice?
    
    var currentDeviceInput: AVCaptureDeviceInput?
    
//    var videoVC = VideoViewController()
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    // location label
    let locationLabel = LCLabel(textAlignment: .center, fontSize: 15)
    let dateLabel = LCLabel()
    let addressLabel = LCLabel()
    
    var locationManager = CLLocationManager()
    
    let currentDate = Date()
    let formatter = DateFormatter()
    
    enum CameraErrors: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    let photoButton = UIButton()

    var cameraButton: UIButton = {
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
    
    let photoImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
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
    
    private let settingsButton: UIButton = {
        let button = UIButton()
        return button
    }()
     
     private let stopVideoButton: UIButton = {
         var buttonConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular, scale: .large)
         buttonConfig = buttonConfig.applying(UIImage.SymbolConfiguration(paletteColors: [UIColor.white, UIColor.systemRed]))
         let stopVideo = UIImage(systemName: "square.fill", withConfiguration: buttonConfig)
         let button = UIButton()
         
         button.setImage(stopVideo, for: .normal)
         button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
         
         return button
     }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemYellow
        view.layer.addSublayer(previewLayer)
        view.addSubview(cameraButton)

//        view.addSubview(locationLabel)
//        view.addSubview(dateLabel)
        checkCameraPermissions()

        cameraButton.addTarget(self, action: #selector(tappedCameraButton), for: .touchUpInside)
        flipCameraButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)

        configureFlipCameraButton()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        dateLabel.text = formatter.string(from: currentDate)
        
        configureLabels()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer.frame = view.bounds
        
        cameraButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 80)
    }
    
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // request permission
            // AVCapture devices are inputs that you can give to a capture session - things like the front facing camera, back camera, the mic, the telephoto lens, etc
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    return
                }
                // if permission was granted call setupCamera on the main thread
                DispatchQueue.main.async {
                    self?.setUpCamera(position: .back)
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera(position: .back)
        @unknown default:
            break
        }
    }
    
    private func setUpCamera(position: AVCaptureDevice.Position) {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        // Remove existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }
        
        // Add video input
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
            } catch {
                print("Could not create video device input: \(error)")
            }
        }
        
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }
        
        // Set up preview layer
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.session = session
        
        // Start running the session
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
        
        self.session = session
    }

    
    @objc private func tappedCameraButton() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private var currentCameraInput: AVCaptureDeviceInput?
    
    
    @objc func switchCamera() {
        guard let currentCameraInput = session?.inputs.first as? AVCaptureDeviceInput else {
            return
        }

        session?.beginConfiguration()
        session?.removeInput(currentCameraInput)

        let newCameraPosition: AVCaptureDevice.Position = currentCameraInput.device.position == .back ? .front : .back
        let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newCameraPosition)

        do {
            let newVideoInput = try AVCaptureDeviceInput(device: newCamera!)
            if ((session?.canAddInput(newVideoInput)) != nil) {
                session?.addInput(newVideoInput)
            }
        } catch let error {
            print("Error adding video input: \(error.localizedDescription)")
            session?.addInput(currentCameraInput)
        }

        session?.commitConfiguration()
    }
    
//    func applyScaleFactorTo(frame: CGRect,scaleFactor: CGFloat) -> CGRect {
//        return CGRectApplyAffineTransform(frame, CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))
//    }
    
    /*
    /// Given a frame (CGRect), apply the given scale factor to it.
        /// - Parameters:
        ///   - frame: The rectangle that defines an area within another area.
        ///   - scaleFactor: The difference in scale between the current frame and the destination scale.
        /// - Returns: A frame (rectangle) scaled based on the scale factor.
    func applyScaleFactorTo(frame: CGRect, scaleFactor: CGFloat) -> CGRect {
        // scaleFactor: 4
        // x: 10, y: 10, w: 10, h: 80
        let x = frame.origin.x * scaleFactor // 10 * 4 = 40
        let y = frame.origin.y * scaleFactor // 10 * 4 = 40
        let height = frame.height * scaleFactor // 10 * 4 = 40
        let width = frame.width * scaleFactor // 80 * 4 = 320
        return CGRect(x: x, y: y, width: width, height: height)
        // x: 40, y: 40, w: 40, h: 320
    }
    */
    private func savePhoto(_ image: UIImage) {
        // Capture the current state of the labels within the view hierarchy
        if let dateLabelImage = captureViewAsImage(view: dateLabel, scale: image.scale),
           let locationLabelImage = captureViewAsImage(view: locationLabel, scale: image.scale) {
            
            // Create a graphics context with the size of the base image
            UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
            
            // Draw the base image
            image.draw(at: CGPoint.zero)
            
            // Draw the Date and Location labels at their original positions
//            let dateLabelFrame = CGRectApplyAffineTransform(dateLabel.frame, CGAffineTransform(scaleX: image.scale, y: image.scale))
//            let dateLabelFrame = applyScaleFactorTo(frame: dateLabel.frame, scaleFactor: image.scale)
//            print(dateLabelFrame)
            dateLabelImage.draw(in: dateLabel.frame)
//            let locationLabelFrame = CGRectApplyAffineTransform(locationLabel.frame, CGAffineTransform(scaleX: image.scale, y: image.scale))
//            let locationLabelFrame = applyScaleFactorTo(frame: locationLabel.frame, scaleFactor: image.scale)
//            print(locationLabelFrame)
            locationLabelImage.draw(in: locationLabel.frame)
            
            // Get the combined image from the graphics context
            let outputImageWithData = UIGraphicsGetImageFromCurrentImageContext()
            
            // End the graphics context
            UIGraphicsEndImageContext()
            
            // Save the resulting image to the photo library
            if let outputImage = outputImageWithData {
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: outputImage)
                    request.creationDate = Date()
                    
                    // Add location information to the photo
                    if let location = self.locationManager.location {
                        request.location = location
                    }
                }) { [weak self] success, error in
                    if success {
                        print("Photo saved successfully")
                    } else {
                        print("Error saving photo: \(error?.localizedDescription ?? "unknown error")")
                    }
                }
            }
        }
    }

    func captureViewAsImage(view: UIView, scale: CGFloat) -> UIImage? {
        // Capture the view hierarchy as an image
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, scale)
        
        if let context = UIGraphicsGetCurrentContext() {
            view.layer.render(in: context)
            
            // Get the image from the graphics context
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            // End the graphics context
            UIGraphicsEndImageContext()
            
            return image
        } else {
            UIGraphicsEndImageContext()
            return nil
        }
    }

    
    /*
    private func savePhoto(_ image: UIImage) {
        // Create a graphics context with the size of the base image
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        
        // Draw the base image
        image.draw(at: CGPoint.zero)
        
        // Get the current graphics context
        if let context = UIGraphicsGetCurrentContext() {
            // Draw the Date and Location labels at their original positions
            if let dateLabelImage = convertImageFromLabel(label: dateLabel),
               let locationLabelImage = convertImageFromLabel(label: locationLabel) {
                
                let dateLabelFrame = dateLabel.frame
                let locationLabelFrame = locationLabel.frame
                
                dateLabelImage.draw(in: dateLabelFrame)
                locationLabelImage.draw(in: locationLabelFrame)
            }
            
            // Get the combined image from the graphics context
            let outputImageWithData = UIGraphicsGetImageFromCurrentImageContext()
            
            // End the graphics context
            UIGraphicsEndImageContext()
            
            // Save the resulting image to the photo library
            if let outputImage = outputImageWithData {
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetChangeRequest.creationRequestForAsset(from: outputImage)
                    request.creationDate = Date()
                    
                    // Add location information to the photo
                    if let location = self.locationManager.location {
                        request.location = location
                    }
                }) { [weak self] success, error in
                    if success {
                        print("Photo saved successfully")
                    } else {
                        print("Error saving photo: \(error?.localizedDescription ?? "unknown error")")
                    }
                }
            }
        }
    }

    
    func convertImageFromLabel(label: UILabel) -> UIImage?  {
        // Create a graphics context with the size of the label's frame
        UIGraphicsBeginImageContextWithOptions(label.frame.size, false, 0.0)
        
        // Render the label into the graphics context
        if let context = UIGraphicsGetCurrentContext() {
            label.layer.render(in: context)
            
            // Get the image from the graphics context
            let imageFromLabel = UIGraphicsGetImageFromCurrentImageContext()
            
            // End the graphics context
            UIGraphicsEndImageContext()
            
            return imageFromLabel
        } else {
            UIGraphicsEndImageContext()
            return nil
        }
    }
    */
    
    /*
    private func savePhoto(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.creationDate = Date()

            // Add location information to the photo
            if let location = self.locationManager.location {
                request.location = location
            }

            // Add a text overlay with the date and location
            let formattedDate = self.formatter.string(from: Date())
            let locationText = locationLabel.text

            let textFontAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 18)
            ]

            // Create an image with the text overlay
            UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
            image.draw(at: .zero)
            formattedDate.draw(at: CGPoint(x: 20, y: 20), withAttributes: textFontAttributes)
            locationText?.draw(at: CGPoint(x: 20, y: image.size.height - 50), withAttributes: textFontAttributes)
            if let newImage = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()

                // Save the modified image as JPEG data and then create an asset from the data
                if let data = newImage.jpegData(compressionQuality: 0.9) {
                    request.addResource(with: .photo, data: data, options: nil)
                }
            } else {
                UIGraphicsEndImageContext()
            }

        }) { [weak self] success, error in
            if success {
                print("Photo saved successfully")
            } else {
                print("Error saving photo: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    */

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationLabel.text = "Lat: \(location.coordinate.latitude) Lon: \(location.coordinate.longitude)"
    }
    
   
    // MARK: - Auto Layout
    // Auto Layout
    
    func configureFlipCameraButton() {
        view.addSubview(flipCameraButton)
        
        NSLayoutConstraint.activate([
            flipCameraButton.widthAnchor.constraint(equalToConstant: 50),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 50),
            flipCameraButton.centerYAnchor.constraint(equalTo: cameraButton.centerYAnchor),
            flipCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    }
    
    func configureLabels() {
        let locationLabelSize = locationLabel.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        let dateLabelSize = dateLabel.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        
        // Set the bounds of the label to the appropriate size
        dateLabel.bounds = CGRect(x: 0, y: 0, width: 200, height: 30)
        
        // Rotate the label by 90 degrees
        dateLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.backgroundColor = .white
        
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: dateLabel.centerXAnchor, constant: 20 + dateLabelSize.height / 2),
            view.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor)
        ])
        
        locationLabel.bounds = CGRect(x: 0, y: 0, width: 200, height: 30)
        locationLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2 - locationLabelSize.height / 2)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.backgroundColor = .white

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: locationLabel.centerXAnchor, constant: -20),
            view.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor)
        ])
    }
}

extension PhotoViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            // show the captured photo in your image view
            photoImageView.image = image
            // save the photo to the photo library
            savePhoto(image)
        }
    }
}

*/
