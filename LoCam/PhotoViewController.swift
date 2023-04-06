
import AVFoundation
import CoreLocation
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
    
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var backInput: AVCaptureInput!
    var frontInput: AVCaptureInput!
    
    var segmentImage = UIImageView()
    
    var videoVC = VideoViewController()
    
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

        configureFlipCameraButton()
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager?.requestWhenInUseAuthorization()

        dateLabel.text = "\(Date.now)"
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

                if session.canAddOutput(photoOutput) {
                    session.addOutput(photoOutput)
                }

                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session

                session.startRunning()
                self.session = session
            }
            catch {
                print(error)
            }

            // Add audio device
            do {
                let audioDevice = AVCaptureDevice.default(for: .audio)
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)

                if session.canAddInput(audioDeviceInput) {
                    session.addInput(audioDeviceInput)
                } else {
                    print("Could not add audio device input to the session")
                }
            } catch {
                print("Could not create audio device input: \(error)")
            }
        }
    }

    
    @objc private func tappedCameraButton() {
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
    
   
    // MARK: - Auto Layout
    // Auto Layout
    func configurePhotoButton() {
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
            flipCameraButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            flipCameraButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10)
        ])
    }
    
    func configureStartRecordVideoButton() {
        view.addSubview(startVideoButton)
        startVideoButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            startVideoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            startVideoButton.heightAnchor.constraint(equalToConstant: 70),
            startVideoButton.widthAnchor.constraint(equalToConstant: 35)
        ])
    }
    
    func configureStopRecordVideoButton() {
        NSLayoutConstraint.activate([
            stopVideoButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            stopVideoButton.heightAnchor.constraint(equalToConstant: 70),
            stopVideoButton.widthAnchor.constraint(equalToConstant: 35)
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
    
}

extension PhotoViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        
        guard let image = UIImage(data: data) else { return }
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
    }
}

