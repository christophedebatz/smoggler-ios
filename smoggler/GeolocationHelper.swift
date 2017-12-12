//
//  GeolocationHelper.swift
//  smoggler
//
//  Created by Christophe de Batz on 11/12/2017.
//  Copyright © 2017 Christophe de Batz. All rights reserved.
//

import Foundation
import CoreLocation

public class GeolocationHelper {
    
    let locationManager: CLLocationManager = CLLocationManager()
    let coordsCompletion: (String, String) -> Void
    
    init(coordsCompletion: @escaping (String, String) -> Void) {
        self.coordsCompletion = coordsCompletion;

        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.delegate = self as? CLLocationManagerDelegate
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        let coords: CLLocationCoordinate2D = (locationManager.location?.coordinate)!
        coordsCompletion(String(coords.latitude), String(coords.longitude))
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdatingLocation()
        }
    }

}
