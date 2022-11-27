//
//  LocationManager.swift
//  LoCam
//
//  Created by Femi Aliu on 20/10/2022.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    let manager = CLLocationManager()
    
    var completion: ((CLLocation) -> Void)?
    
    public func getUserLocation(completion: @escaping ((CLLocation) -> Void )) {
        self.completion = completion
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
        manager.startUpdatingLocation()
        
        if CLLocationManager.locationServicesEnabled() {
            // location enabled
            print("location enabled")
            manager.startUpdatingLocation()
        } else {
            // location not enabled
            print("location not enabled")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        completion?(location)
        manager.stopUpdatingLocation()
        
        // get current location
//        let currentLocation = locations[0] as CLLocation
        
        // get lattitude and longitude
//        let latitude = currentLocation.coordinate.latitude
//        let longitude = currentLocation.coordinate.longitude
    }
}
