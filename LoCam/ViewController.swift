//
//  ViewController.swift
//  LoCam
//
//  Created by Femi Aliu on 15/04/2022.
//

import AVFoundation
import CoreLocation
import Photos
import UIKit

class ViewController: UIViewController, CLLocationManagerDelegate {
//    let videoOutput = AVCaptureMovieFileOutput()
//    let videoOutput = AVCaptureVideoDataOutput()
    
    // Capture Session
    var session: AVCaptureSession?
    // Photo Output
    let output = AVCapturePhotoOutput()
    // Video Preview
    let previewLayer = AVCaptureVideoPreviewLayer()
    // Camera Button
    let photoCameraButton = LCButton()
    let videoCameraButton = LCButton()
    let flipCamera = LCButton()
    
    var videoFileOutput: AVCaptureMovieFileOutput?
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    // location label
    let locationLabel = LCLabel(textAlignment: .center, fontSize: 15)
    let dateLabel = LCLabel()
    let addressLabel = LCLabel()
    
    var locationManager: CLLocationManager?
    let currentDate = Date()
    
    enum CameraErrors: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    // let photoButton
    private let cameraButton: UIButton = {
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
    
    /*
    private let videoButton: UIButton = {
        var buttonConfig = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular, scale: .large)
        buttonConfig = buttonConfig.applying(UIImage.SymbolConfiguration(paletteColors: [UIColor.systemRed, UIColor.white]))
        let videoButton = UIImage(systemName: "square.inset.filled", withConfiguration: buttonConfig)
        let button = UIButton()
        
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        
        return button
    }()
    
    private let settingsButton: UIButton = {
        let button = UIButton()
        return button
    }()
    */
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemCyan
        view.layer.addSublayer(previewLayer)
        view.addSubview(cameraButton)
        view.addSubview(locationLabel)
        view.addSubview(dateLabel)
        checkCameraPermissions()
        
        cameraButton.addTarget(self, action: #selector(tappedCameraButton), for: .touchUpInside)
//        locationLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
//        configurePhotoButton()
        configureLabels()
        getUserLocation()
        configureFlipCameraButton()
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager?.requestWhenInUseAuthorization()
//        var currentLocation: CLLocation!

//        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways {
//            currentLocation = locationManager?.location
//        }
        
//        switch locationManager?.authorizationStatus {
//        case .restricted, .denied:
//            return
//        default:
//            locationManager?.startUpdatingLocation()
//        }
        
//        locationLabel.text = "\(currentLocation.coordinate.longitude), \(currentLocation.coordinate.latitude)"
        
        dateLabel.text = "\(Date.now)"
//        locationLabel.text = "\(latitude), \(longitude)"
        
        /*
        LocationManager.shared.getUserLocation { [weak self] location in
            DispatchQueue.main.async {
                guard let strongSelf = self else {
                    return
                }
                
                // get current location
                let currentLocation = locations[0] as CLLocation
                
                // get lattitude and longitude
                let latitude = currentLocation.coordinate.latitude
                let longitude = currentLocation.coordinate.longitude
            }
        }
        */
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer.frame = view.bounds

        cameraButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 80)
        
//        photoCameraButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 100)
//        configurePhotoButton()
//        configureLabels()
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
    
    private func setUpCamera() {
        let session = AVCaptureSession()
        // try to get the device that we want to add
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                session.startRunning()
                self.session = session
            }
            catch {
                print(error)
            }
        }
    }
    
    @objc private func tappedCameraButton() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
    /*
    func recordVideo() {
        guard let videoFileOutput = self.videoFileOutput else {
            return
        }
        
        let videoPreviewLayerOrientation = previewLayer.videoPreviewLayer.connection?.videoOrientation
        
        sessionQueue.async {
            if !videoFileOutput.isRecording {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }
                
                // Update the orientation on the movie file output video connection before recording.
                let videoFileOutputConnection = videoFileOutput.connection(with: .video)
                videoFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!
                
                let availableVideoCodecTypes = videoFileOutput.availableVideoCodecTypes
                
                if availableVideoCodecTypes.contains(.hevc) {
                    videoFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: videoFileOutputConnection!)
                }
                
                // Start recording video to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                videoFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
            } else {
                videoFileOutput.stopRecording()
            }
        }
    }
    
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        // Note: Because we use a unique file path for each recording, a new recording won't overwrite a recording mid-save.
        func cleanup() {
            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
            
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
                
                if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
        }
        
        var success = true
        
        if error != nil {
            print("Movie file finishing error: \(String(describing: error))")
            success = (((error! as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)!
        }
        
        if success {
            // Check the authorization status.
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Save the movie file to the photo library and cleanup.
                    PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: options)
                        
                        // Specify the location the movie was recoreded
                        creationRequest.location = self.locationManager.location
                    }, completionHandler: { success, error in
                        if !success {
                            print("AVCam couldn't save the movie to your photo library: \(String(describing: error))")
                        }
                        cleanup()
                    }
                    )
                } else {
                    cleanup()
                }
            }
        } else {
            cleanup()
        }
        
        // Enable the Camera and Record buttons to let the user switch camera and start another recording.
        DispatchQueue.main.async {
            // Only enable the ability to change camera if the device has more than one camera.
            self.cameraButton.isEnabled = self.videoDeviceDiscoverySession.uniqueDevicePositionsCount > 1
            self.recordButton.isEnabled = true
            self.captureModeControl.isEnabled = true
            self.recordButton.setImage(#imageLiteral(resourceName: "CaptureVideo"), for: [])
        }
    }
    
    */
    
    // Auto Layout
    func configurePhotoButton() {
//        view.addSubview(cameraButton)
        photoCameraButton.addTarget(self, action: #selector(tappedCameraButton), for: .touchUpInside)
//        photoCameraButton.layer.borderColor = UIColor.white.cgColor
        photoCameraButton.layer.backgroundColor = UIColor.systemRed.cgColor
//        photoCameraButton.tintColor = .white
        
//        cameraButton.frame = CGRect(x: 0, y: 0, width: 140, height: 140)
        
        NSLayoutConstraint.activate([
            photoCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            photoCameraButton.heightAnchor.constraint(equalToConstant: 70),
            photoCameraButton.widthAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    func configureFlipCameraButton() {
        view.addSubview(flipCameraButton)
        
        NSLayoutConstraint.activate([
            flipCameraButton.widthAnchor.constraint(equalToConstant: 50),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 50),
            flipCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            flipCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    }
    
    func configureLabels() {
        
        locationLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        locationLabel.textColor = .white
        
        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            locationLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
        
        dateLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        dateLabel.textColor = .white
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
//            dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -5),
            dateLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: dateLabel.intrinsicContentSize.width / 2 - dateLabel.intrinsicContentSize.height),
            dateLabel.heightAnchor.constraint(equalToConstant: 15)
        ])
    }
    
    
    func getUserLocation() {
        // location manager configuration
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestWhenInUseAuthorization()
        
        // check if location/gps is enabled or not
        if CLLocationManager.locationServicesEnabled() {
            // location enabled
            print("Location enabled")
            locationManager?.startUpdatingLocation()
        } else {
            // location not enabled
            print("Location not enabled")
        }
        
//        locationLabel.text =
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // get current location
        let deviceLocation = locations[0] as CLLocation
        
        // get lattitude and longitude
        let latitude = deviceLocation.coordinate.latitude
        let longitude = deviceLocation.coordinate.longitude
        
        locationLabel.text = "\(latitude), \(longitude)"
        
        // get address
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(deviceLocation) { (placemarks, error) in
            if (error != nil) {
                print("Error in reverseGeocodeLocation")
            }
            let placemark = placemarks! as [CLPlacemark]
            if (placemark.count>0) {
                let placemark = placemarks![0]
                
                let locality = placemark.locality ?? ""
                let administrativeArea = placemark.administrativeArea ?? ""
                let country = placemark.country ?? ""
                
                self.addressLabel.text = "\(locality), \(administrativeArea), \(country)"
            }
        }
        
    }
}


extension ViewController: AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        
        guard let image = UIImage(data: data) else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        /*
        session?.stopRunning()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.addSubview(imageView)
         */
    }
}

