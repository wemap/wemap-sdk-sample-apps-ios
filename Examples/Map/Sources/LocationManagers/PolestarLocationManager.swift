//
//  PolestarLocationManager.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 10/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Mapbox
import NAOSwiftProvider
import WemapCoreSDK
import WemapMapSDK

class PolestarIndoorLocationProvider: NSObject, IndoorLocationProvider, MGLLocationManager {
    
    weak var indoorDelegate: IndoorLocationProviderDelegate?
    weak var delegate: MGLLocationManagerDelegate?

    private let locationProvider = LocationProvider(apikey: "emulator")
    private let locationManager = CLLocationManager()
    
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
        locationProvider.delegate = self
    }

    func requestAlwaysAuthorization() {
        // no-op
    }

    func requestWhenInUseAuthorization() {
        // no-op
    }

    func startUpdatingLocation() {
        locationProvider.start()
    }

    func stopUpdatingLocation() {
        locationProvider.stop()
    }

    func startUpdatingHeading() {
        // no-op
    }

    func stopUpdatingHeading() {
        // no-op
    }

    func dismissHeadingCalibrationDisplay() {
        // no-op
    }
    
    deinit {
        stopUpdatingLocation()
        locationProvider.delegate = nil
        delegate = nil
    }
}

extension PolestarIndoorLocationProvider: LocationProviderDelegate {
    
    func didLocationChange(_ location: CLLocation!) {
        
        let levelByAltitude = location.altitude / 5
        let coordinate = Coordinate(location: location, levels: [Float(levelByAltitude)])
        
        indoorDelegate?.locationProvider(self, didUpdateLocation: coordinate)
        delegate?.locationManager(self, didUpdate: [location])
        
        print("didLocationChange with location - \(location!), altitude - \(location!.altitude), level - \(levelByAltitude)")
    }
    
    func didLocationStatusChanged(_ status: String!) {
        print("didLocationStatusChanged with status - \(status!)")
    }
    
    func didEnterSite(_ name: String!) {
        print("didEnterSite with name - \(name!)")
    }
    
    func didExitSite(_ name: String!) {
        print("didExitSite with status - \(name!)")
    }
    
    func didApikeyReceived(_ apikey: String!) {
        print("didApikeyReceived with status - \(apikey!)")
    }
    
    func didLocationFailWithErrorCode(_ message: String!) {
        let error = NSError(domain: message, code: -1)
        indoorDelegate?.locationProvider(self, didFailWithError: error)
        delegate?.locationManager(self, didFailWithError: error)
        print("didLocationFailWithErrorCode with errorCode - \(message!)")
    }
    
    func requiresWifiOn() {
        print("requiresWifiOn")
    }
    
    func requiresBLEOn() {
        print("requiresBLEOn")
    }
    
    func requiresLocationOn() {
        print("requiresLocationOn")
    }
    
    func requiresCompassCalibration() {
        print("requiresCompassCalibration")
    }
    
    func didSynchronizationSuccess() {
        print("didSynchronizationSuccess")
    }
    
    func didSynchronizationFailure(_ message: String!) {
        print("didSynchronizationFailure with message - \(message!)")
    }
}

extension PolestarIndoorLocationProvider: CLLocationManagerDelegate {
    
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
