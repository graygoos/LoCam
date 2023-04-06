
import AVFoundation
import Photos
import UIKit

class RecordViewController: UIViewController {

    private let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var permissionGranted = false
    private let captureSessionQueue = DispatchQueue(label: "captureSessionQueue")

    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.frame
        preview.videoGravity = .resizeAspectFill
        return preview
    }()

    private let startRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Record", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(startRecord), for: .touchUpInside)
        return button
    }()

    private let stopRecordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stop Record", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        button.isEnabled = false
        button.addTarget(self, action: #selector(stopRecord), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(startRecordButton)
        view.addSubview(stopRecordButton)
        startRecordButton.translatesAutoresizingMaskIntoConstraints = false
        stopRecordButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            startRecordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startRecordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stopRecordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopRecordButton.topAnchor.constraint(equalTo: startRecordButton.bottomAnchor, constant: 16)
        ])

        checkPermission()
    }

    @objc private func startRecord() {
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

            startRecordButton.isEnabled = false
            stopRecordButton.isEnabled = true
        }
    }

    @objc private func stopRecord() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            startRecordButton.isEnabled = true
            stopRecordButton.isEnabled = false
        }
    }

    private func checkPermission() {
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

    private func setupCaptureSession() {
        guard permissionGranted else { return }
        session.beginConfiguration()
        session.sessionPreset = .high

        let camera = AVCaptureDevice.default(for: .video)
        let cameraInput: AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: camera!)
        } catch {
            print("Error setting device video input: \(error)")
            return
        }

        if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
        view.layer.addSublayer(previewLayer)
        session.startRunning()
    }
}

extension RecordViewController: AVCaptureFileOutputRecordingDelegate {
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



/*
import UIKit
import AVFoundation

class SampleViewController: UIViewController {
    
    
    
    let captureSession = AVCaptureSession()
    let movieOutput = AVCaptureMovieFileOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCaptureSession()
                } else {
                    self.showCameraAccessDeniedAlert()
                }
            }
        case .denied:
            showCameraAccessDeniedAlert()
        case .restricted:
            showCameraAccessRestrictedAlert()
        @unknown default:
            break
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if !granted {
                    self.showMicrophoneAccessDeniedAlert()
                }
            }
        case .denied:
            showMicrophoneAccessDeniedAlert()
        case .restricted:
            showMicrophoneAccessRestrictedAlert()
        @unknown default:
            break
        }
        
        let startRecordingButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        startRecordingButton.setTitle("Start Recording", for: .normal)
        startRecordingButton.setTitleColor(.black, for: .normal)
        startRecordingButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        view.addSubview(startRecordingButton)
        
        let stopRecordingButton = UIButton(frame: CGRect(x: 100, y: 200, width: 100, height: 50))
        stopRecordingButton.setTitle("Stop Recording", for: .normal)
        stopRecordingButton.setTitleColor(.black, for: .normal)
        stopRecordingButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        view.addSubview(stopRecordingButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.layer.bounds
        }
    }
    
    func setupCaptureSession() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let microphone = AVCaptureDevice.default(for: .audio) else {
            showCameraOrMicrophoneSetupFailureAlert()
            return
        }
        
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            let microphoneInput = try AVCaptureDeviceInput(device: microphone)
            
            if captureSession.canAddInput(cameraInput) && captureSession.canAddInput(microphoneInput, captureSession.addInput(cameraInput), captureSession.addInput(microphoneInput)
                                                                                     
                                                                                     
            if captureSession.canAddOutput(movieOutput)) {
                captureSession.addOutput(movieOutput)
            } else {
                showMovieOutputSetupFailureAlert()
                return
            }
            } catch {
                showCameraOrMicrophoneSetupFailureAlert()
                return
            }
                                                                                     
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.frame = view.layer.bounds
                previewLayer.videoGravity = .resizeAspectFill
                view.layer.addSublayer(previewLayer)
                                                                                     
                captureSession.startRunning()
            }
                                                                                     
        @objc func startRecording() {
                let fileURL = URL(fileURLWithPath: NSTemporaryDirectory() + "temp.mov")
                movieOutput.startRecording(to: fileURL, recordingDelegate: self)
            }
                                                                                     
        @objc func stopRecording() {
                movieOutput.stopRecording()
            }
                                                                                     
        func showCameraAccessDeniedAlert() {
                let alert = UIAlertController(title: "Camera Access Denied", message: "Please grant access to the camera in the device settings", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
                                                                                     
        func showCameraAccessRestrictedAlert() {
                let alert = UIAlertController(title: "Camera Access Restricted", message: "Camera access has been restricted, please contact device administrator", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
                                                                                     
        func showMicrophoneAccessDeniedAlert() {
                let alert = UIAlertController(title: "Microphone Access Denied", message: "Please grant access to the microphone in the device settings", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
                                                                                     
        func showMicrophoneAccessRestrictedAlert() {
                let alert = UIAlertController(title: "Microphone Access Restricted", message: "Microphone access has been restricted, please contact device administrator", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
                                                                                     
        func showCameraOrMicrophoneSetupFailureAlert() {
                let alert = UIAlertController(title: "Camera or Microphone Setup Failure", message: "Please check the setup of the camera and microphone on the device and try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
                                                                                     
        func showMovieOutputSetupFailureAlert() {
                let alert = UIAlertController(title: "Movie Output Setup Failure", message: "Failed to setup movie output,
                                              please try again", preferredStyle: .alert)
                                              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                              present(alert, animated: true, completion: nil)
                                              }
                                              }
                                              
                                              
extension SampleViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
                        
                    }
                    
}
                                              
                                              
                                              
*/
