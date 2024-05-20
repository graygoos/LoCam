




import UIKit
import AVFoundation
import Photos


class VideoViewController: UIViewController {
    /*
    var isRecording: Bool = false
    private var permissionGranted = false
    var videoSession = AVCaptureSession()

    var movieOutput = AVCaptureMovieFileOutput()
    let captureSessionQueue = DispatchQueue(label: "captureSessionQueue")
    
    var previewLayer = AVCaptureVideoPreviewLayer()
    
    
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
        
        checkCameraPermissions()
        setUpVideoCamera()
        
        view.backgroundColor = .blue
        view.layer.addSublayer(previewLayer)
        previewLayer.backgroundColor = UIColor.systemPink.cgColor

        view.addSubview(startVideoButton)
        startVideoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startVideoButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            startVideoButton.widthAnchor.constraint(equalToConstant: 80),
            startVideoButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        view.addSubview(stopVideoButton)
        stopVideoButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopVideoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopVideoButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            stopVideoButton.widthAnchor.constraint(equalToConstant: 80),
            stopVideoButton.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        stopVideoButton.isHidden = true
        
        startVideoButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        
        stopVideoButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
    }
    

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer.frame = view.bounds
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        captureSessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
            self.permissionGranted = granted
            self.captureSessionQueue.resume()
        }
    }
    
    
    private func setUpVideoCamera() {

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

            startVideoButton.isHidden = true
            stopVideoButton.isHidden = false
        }
    }
    
    @objc func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            startVideoButton.isHidden = false
            stopVideoButton.isHidden = true
        }
    }
    */
}

extension VideoViewController: AVCaptureFileOutputRecordingDelegate {
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
}

