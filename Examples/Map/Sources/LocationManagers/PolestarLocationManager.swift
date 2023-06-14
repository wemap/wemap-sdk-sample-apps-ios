//
//  PolestarLocationManager.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 10/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Mapbox
import NAOSwiftProvider
import WemapCoreSDK
import WemapMapSDK

class PolestarIndoorLocationProvider: NSObject, IndoorLocationProvider, MGLLocationManager {
    
    var lastCoordinate: Coordinate?
    
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
        locationManager.delegate = self
        locationProvider.delegate = self
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
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
        locationManager.dismissHeadingCalibrationDisplay()
    }
    
    deinit {
        stopUpdatingLocation()
        locationProvider.delegate = nil
        locationManager.delegate = nil
        delegate = nil
    }
}

extension PolestarIndoorLocationProvider: LocationProviderDelegate {
    
    func didLocationChange(_ location: CLLocation!) {
        
        let levelByAltitude = location.altitude / 5
        let coordinate = Coordinate(location: location, levels: [Float(levelByAltitude)])
        
        lastCoordinate = coordinate
        indoorDelegate?.locationProvider(self, didUpdateLocation: coordinate)
        delegate?.locationManager(self, didUpdate: [location])
        
        debugPrint("didLocationChange with location - \(location!), altitude - \(location!.altitude), level - \(levelByAltitude)")
    }
    
    func didLocationStatusChanged(_ status: String!) {
        debugPrint("didLocationStatusChanged with status - \(status!)")
    }
    
    func didEnterSite(_ name: String!) {
        debugPrint("didEnterSite with name - \(name!)")
    }
    
    func didExitSite(_ name: String!) {
        debugPrint("didExitSite with status - \(name!)")
    }
    
    func didApikeyReceived(_ apikey: String!) {
        debugPrint("didApikeyReceived with status - \(apikey!)")
    }
    
    func didLocationFailWithErrorCode(_ message: String!) {
        let error = NSError(domain: message, code: -1)
        indoorDelegate?.locationProvider(self, didFailWithError: error)
        delegate?.locationManager(self, didFailWithError: error)
        debugPrint("didLocationFailWithErrorCode with errorCode - \(message!)")
    }
    
    func requiresWifiOn() {
        debugPrint("requiresWifiOn")
    }
    
    func requiresBLEOn() {
        debugPrint("requiresBLEOn")
    }
    
    func requiresLocationOn() {
        debugPrint("requiresLocationOn")
    }
    
    func requiresCompassCalibration() {
        debugPrint("requiresCompassCalibration")
    }
    
    func didSynchronizationSuccess() {
        debugPrint("didSynchronizationSuccess")
    }
    
    func didSynchronizationFailure(_ message: String!) {
        debugPrint("didSynchronizationFailure with message - \(message!)")
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
