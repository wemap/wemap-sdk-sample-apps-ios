//
//  PolestarIndoorLocationProvider.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 10/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Mapbox
import NAOSwiftProvider
import WemapCoreSDK
import WemapMapSDK

class PolestarIndoorLocationProvider: NSObject, IndoorLocationProvider {
    
    var lastCoordinate: Coordinate?
    
    weak var indoorDelegate: IndoorLocationProviderDelegate?

    private let locationProvider = LocationProvider(apikey: "emulator")

    override init() {
        super.init()
        locationProvider.delegate = self
    }

    func startUpdatingLocation() {
        locationProvider.start()
    }

    func stopUpdatingLocation() {
        locationProvider.stop()
    }
    
    deinit {
        stopUpdatingLocation()
        locationProvider.delegate = nil
    }
}

extension PolestarIndoorLocationProvider: LocationProviderDelegate {
    
    func didLocationChange(_ location: CLLocation!) {
        
        let levelByAltitude = location.altitude / 5
        let coordinate = Coordinate(location: location, levels: [Float(levelByAltitude)])
        
        lastCoordinate = coordinate
        indoorDelegate?.locationProvider(self, didUpdateLocation: coordinate)
        
//        debugPrint("didLocationChange with location - \(location!), altitude - \(location!.altitude), level - \(levelByAltitude)")
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
