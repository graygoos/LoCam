
import AVFoundation
import CoreLocation
import Photos
import UIKit

import MobileCoreServices
import CoreServices

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
    
    var videoVC = VideoViewController()
    
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

        view.addSubview(locationLabel)
        view.addSubview(dateLabel)
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


    private func savePhoto(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.creationDate = Date()

            // Add location information to the photo
            if let location = self.locationManager.location {
                request.location = location
            }

            // Add a text overlay with the date and location


        }) { [weak self] success, error in
            if success {
                print("Photo saved successfully")
            } else {
                print("Error saving photo: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }


    
    
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

