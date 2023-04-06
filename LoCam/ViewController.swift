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

