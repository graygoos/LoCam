//
//  ViewController.swift
//  LoCam
//
//  Created by Femi Aliu on 15/04/2022.
//

import AVFoundation
import UIKit

import AVFoundation
import UIKit
import Photos
import CoreLocation

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate, CLLocationManagerDelegate {

    // UI Elements
    let segmentedControl = UISegmentedControl(items: ["Photo", "Video"])
    let cameraButton = UIButton()
    let locationLabel = UILabel()
    let dateLabel = UILabel()
    let captureImageView = UIImageView()
    
    // Capture Session
    var session: AVCaptureSession?
    // Photo Output
    let photoOutput = AVCapturePhotoOutput()
    // Video Output
    var videoFileOutput: AVCaptureMovieFileOutput?
    // Video Preview
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    var locationManager = CLLocationManager()
    let formatter = DateFormatter()
    
    var isRecording: Bool = false
    var permissionGranted = false
    var videoSession = AVCaptureSession()
    var movieOutput = AVCaptureMovieFileOutput()
    let captureSessionQueue = DispatchQueue(label: "captureSessionQueue")
    
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
         buttonConfig = buttonConfig.applying(UIImage.SymbolConfiguration(paletteColors: [UIColor.systemRed, UIColor.white]))
         let stopVideo = UIImage(systemName: "square.fill", withConfiguration: buttonConfig)
         let button = UIButton()
         
         button.setImage(stopVideo, for: .normal)
         button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
         
         return button
     }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemRed
        addViewControllersToView()
        configureUI()
        createSegmentedControl()
        checkCameraPermissions()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - UI Configuration
    
    func configureUI() {
        // Configure segmented control
        segmentedControl.addTarget(self, action: #selector(cameraFunctionDidChange(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        
        // Configure camera button
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraButton)
        
        // Configure location label
        locationLabel.textAlignment = .center
        locationLabel.font = UIFont.systemFont(ofSize: 15)
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationLabel)
        
        // Configure date label
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        dateLabel.text = formatter.string(from: Date())
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dateLabel)
        
        // Configure capture image view
        captureImageView.contentMode = .scaleAspectFit
        captureImageView.clipsToBounds = true
        captureImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureImageView)
    }
    
    func createSegmentedControl() {
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }
    
    func positionButtons() {
        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cameraButton.widthAnchor.constraint(equalToConstant: 80),
            cameraButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func configureLabels() {
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    func configureCaptureImageView() {
        NSLayoutConstraint.activate([
            captureImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureImageView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            captureImageView.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -20)
        ])
    }
    
    // MARK: - AVCapture Configuration
    
    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestCameraPermission()
        default:
            permissionGranted = false
        }
    }
    
    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            self?.permissionGranted = granted
        }
    }
    
    func setUpCamera() {
        guard permissionGranted else { return }
        
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        // Remove existing inputs
        for input in session.inputs {
            session.removeInput(input)
        }
        
        // Add video input
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
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
    
    func setUpVideoCamera() {
        guard permissionGranted else { return }
        
        // Set up the capture session
        videoSession.beginConfiguration()
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        let videoDeviceInput = try! AVCaptureDeviceInput(device: videoDevice)
        if videoSession.canAddInput(videoDeviceInput) {
            videoSession.addInput(videoDeviceInput)
        }
        if videoSession.canAddOutput(movieOutput) {
            videoSession.addOutput(movieOutput)
        }
        videoSession.commitConfiguration()

        // Set up the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        // Start the capture session
        videoSession.startRunning()
    }
    
    // MARK: - Action Methods
    
    @objc func cameraFunctionDidChange(_ segmentedControl: UISegmentedControl) {
        if segmentedControl.selectedSegmentIndex == 0 {
            setUpCamera()
            view.bringSubviewToFront(cameraButton)
            view.bringSubviewToFront(locationLabel)
            view.bringSubviewToFront(dateLabel)
            view.bringSubviewToFront(captureImageView)
        } else {
            setUpVideoCamera()
            view.bringSubviewToFront(startVideoButton)
            view.bringSubviewToFront(stopVideoButton)
        }
    }
    
    @objc func cameraButtonTapped() {
        if segmentedControl.selectedSegmentIndex == 0 {
            capturePhoto()
        } else {
            if !isRecording {
                startRecording()
            } else {
                stopRecording()
            }
        }
    }
    
    
    
    func capturePhoto() {
        guard let captureSession = session else { return }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func startRecording() {
        if !movieOutput.isRecording {
            let connection = movieOutput.connection(with: .video)
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = .portrait
            }

            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = .auto
            }

            let device = AVCaptureDevice.default(for: .video)
            if let device = device {
                do {
                    try device.lockForConfiguration()
                    if device.isSmoothAutoFocusSupported {
                        device.isSmoothAutoFocusEnabled = false
                    }
                    device.unlockForConfiguration()
                    let outputPath = NSTemporaryDirectory() + "output.mov"
                    let outputURL = URL(fileURLWithPath: outputPath)
                    movieOutput.startRecording(to: outputURL, recordingDelegate: self)
                } catch {
                    print("Error locking configuration")
                }
            }
        }
    }
    
    @objc func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
    
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
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            // Show the captured photo in the image view
            captureImageView.image = image
            // Save the photo to the photo library with location and date watermarks
            savePhoto(image)
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            PHPhotoLibrary.requestAuthorization { [unowned self] status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                    }) { [unowned self] saved, error in
                        if saved {
                            let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alertController.addAction(okAction)
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationLabel.text = "Lat: \(location.coordinate.latitude) Lon: \(location.coordinate.longitude)"
    }
    
    // MARK: - Auto Layout
    
    func addViewControllersToView() {
        // Add segmented control
        view.addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        // Add camera button
        view.addSubview(cameraButton)
        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cameraButton.widthAnchor.constraint(equalToConstant: 80),
            cameraButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Add location label
        view.addSubview(locationLabel)
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 10),
            locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
        
        // Add date label
        view.addSubview(dateLabel)
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
        
        // Add capture image view
        view.addSubview(captureImageView)
        NSLayoutConstraint.activate([
            captureImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            captureImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            captureImageView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            captureImageView.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -20)
        ])
        
        // Hide capture image view initially
        captureImageView.isHidden = true
    }
}


/*
class ViewController: UIViewController {
    
    let segmentedControl = UISegmentedControl(items: ["Photo", "Video"])
    
    let photoVC = PhotoViewController()
    let videoVC = VideoViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemRed
        addViewControllersToView()
        view.addSubview(segmentedControl)
        createSegmentedControl()
        
//        positionButtons()
    }
    
    func createSegmentedControl() {
        segmentedControl.addTarget(self, action: #selector(cameraFunctionDidChange(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.backgroundColor = .systemBackground
        

        NSLayoutConstraint.activate([
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            segmentedControl.bottomAnchor.constraint(equalTo: cameraButton.topAnchor, constant: -20)
            segmentedControl.bottomAnchor.constraint(equalTo: photoVC.cameraButton.topAnchor, constant: -20)
        ])
    }

    @objc func cameraFunctionDidChange(_ segmentedControl: UISegmentedControl) {
        if segmentedControl.selectedSegmentIndex == 0 {
            photoVC.view.isHidden = false
            videoVC.view.isHidden = true
            print("photo vc")
        } else {
            photoVC.view.isHidden = true
            videoVC.view.isHidden = false
            print("switched to video vc")
//            videoVC.isRecording = false
//            if videoVC.isRecording == true { segmentedControl.isHidden = true }
        }
    }
    
    func positionButtons() {
        NSLayoutConstraint.activate([
            photoVC.cameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            photoVC.cameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            photoVC.cameraButton.widthAnchor.constraint(equalToConstant: 80),
            photoVC.cameraButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func addViewControllersToView() {
        // Add the photo and video view controllers as child view controllers
        addChild(photoVC)
        view.addSubview(photoVC.view)
        photoVC.view.frame = view.bounds
        photoVC.didMove(toParent: self)
        
        addChild(videoVC)
        view.addSubview(videoVC.view)
        videoVC.view.frame = view.bounds
        videoVC.didMove(toParent: self)
        
        // Hide the video view controller initially
        videoVC.view.isHidden = true
    }
}
*/
