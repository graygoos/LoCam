import UIKit
import AVFoundation

class PreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
/*
// Set the bounds of the label to the appropriate size
    dateLabel.bounds = CGRect(x: 0, y: 0, width: 200, height: 30)

    // Rotate the label by 90 degrees
    dateLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)

    dateLabel.translatesAutoresizingMaskIntoConstraints = false
    dateLabel.backgroundColor = .white

    view.addSubview(dateLabel)

    NSLayoutConstraint.activate([
        dateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        dateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])

    locationLabel.bounds = CGRect(x: 0, y: 0, width: 200, height: 30)
    locationLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
    locationLabel.translatesAutoresizingMaskIntoConstraints = false
    locationLabel.backgroundColor = .white

    view.addSubview(locationLabel)

    NSLayoutConstraint.activate([
        locationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        locationLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
 */
/*
 
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
     
     // Remove existing audio inputs
     for input in session.inputs {
         if input is AVCaptureDeviceInput {
             let deviceInput = input as! AVCaptureDeviceInput
             if deviceInput.device.deviceType == .builtInMicrophone {
                 session.removeInput(deviceInput)
             }
         }
     }
     
     // Add audio input
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
     
     // Add photo output
     if session.canAddOutput(photoOutput) {
         session.addOutput(photoOutput)
     }
     
     // Set up preview layer
     previewLayer.videoGravity = .resizeAspectFill
     previewLayer.session = session
     
     // Start running the session
     if !session.isRunning {
         session.startRunning()
     }
     
     self.session = session
 }
 
 */
