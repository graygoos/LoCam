//
//  ViewController.swift
//  LoCam
//
//  Created by Femi Aliu on 15/04/2022.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    // Capture Session
    var session: AVCaptureSession?
    // Photo Output
    let output = AVCapturePhotoOutput()
    // Video Preview
    let previewLayer = AVCaptureVideoPreviewLayer()
    // Camera Button
    private let cameraButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.white.cgColor
        
        return button
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemCyan
        view.layer.addSublayer(previewLayer)
        view.addSubview(cameraButton)
        checkCameraPermissions()
        
        cameraButton.addTarget(self, action: #selector(tappedCameraButton), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewLayer.frame = view.bounds
        
        cameraButton.center = CGPoint(x: view.frame.size.width / 2, y: view.frame.size.height - 100)
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

}


extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        
        let image = UIImage(data: data)
        
        session?.stopRunning()
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.addSubview(imageView)
    }
}
