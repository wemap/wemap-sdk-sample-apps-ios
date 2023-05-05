//
//  CustomLocationManager.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 09/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Mapbox

class CustomLocationManager: NSObject, MGLLocationManager {
    
    private let locationManager = CLLocationManager()
    
    weak var delegate: MGLLocationManagerDelegate?

    var authorizationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }
    
    var headingOrientation: CLDeviceOrientation {
        get {
            locationManager.headingOrientation
        }
        set {
            locationManager.headingOrientation = newValue
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    func dismissHeadingCalibrationDisplay() {
        locationManager.dismissHeadingCalibrationDisplay()
    }
    
    deinit {
        stopUpdatingLocation()
        stopUpdatingHeading()
        locationManager.delegate = nil
        delegate = nil
    }
}

extension CustomLocationManager: CLLocationManagerDelegate {
    
    func locationManagerShouldDisplayHeadingCalibration(_: CLLocationManager) -> Bool {
        if let delegate {
            return delegate.locationManagerShouldDisplayHeadingCalibration(self)
        } else {
            return false
        }
    }

    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        delegate?.locationManagerDidChangeAuthorization(self)
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager(self, didUpdate: locations)
    }

    func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdate: newHeading)
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
}
