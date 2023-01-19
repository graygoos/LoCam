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
    
    var videoFileOutput: AVCaptureMovieFileOutput?
    
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
        
//        button.addTarget(ViewController.self, action: #selector(savePhoto), for: .touchUpInside)
        button.tintColor = .white
        button.setImage(photoButton, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 80)

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
//        cameraButton.addTarget(ViewController.self, action: #selector(savePhoto), for: .touchUpInside)
//        savePhoto()
    }
    
    private func savePhoto() {
        guard let previewImage = self.photoImageView.image else { return }

        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                do {
                    try PHPhotoLibrary.shared().performChangesAndWait {
                        PHAssetChangeRequest.creationRequestForAsset(from: previewImage)
                        print("photo has saved in library...")
                    }
                } catch let error {
                    print("failed to save photo in library:", error)
                }
            } else {
                print("Something went wrong with permission....")
            }
        }
    }
    
    
//    func savePhotos(completion: @escaping (UIImage?, Error) -> Void) {
//        guard let session = session, session.isRunning else { completion(nil, ViewController.captureSessionIsMissing); return }
//    }
    
    
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


extension ViewController: AVCapturePhotoCaptureDelegate {
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

