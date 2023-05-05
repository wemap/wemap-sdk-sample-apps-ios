//
//  ManualLocationManager.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 13/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Mapbox
import WemapCoreSDK
import WemapMapSDK

class ManualLocationManager: RxObject, MGLLocationManager {
    
    weak var delegate: MGLLocationManagerDelegate?
    
    var authorizationStatus: CLAuthorizationStatus {
        get {
            .authorizedAlways
        }
        set {
            fatalError("shouldn't be called")
        }
    }
    
    var headingOrientation: CLDeviceOrientation {
        get {
            .unknown
        }
        set {
            // no-op
        }
    }
    
    init(map: MapView) {
        super.init()
        
        let longPress = UILongPressGestureRecognizer()
        
        longPress.rx
            .event
            .filter { $0.state == .ended }
            .subscribe(onNext: { [unowned self] event in
                let coord = map.convert(event.location(in: map), toCoordinateFrom: map)
                let location = CLLocation(coordinate: coord, altitude: 8, horizontalAccuracy: .infinity, verticalAccuracy: .infinity, timestamp: .init())
                delegate?.locationManager(self, didUpdate: [location])
            }).disposed(by: disposeBag)
        
        map.addGestureRecognizer(longPress)
    }
    
    func requestAlwaysAuthorization() {
        // no-op
    }
    
    func requestWhenInUseAuthorization() {
        // no-op
    }
    
    func startUpdatingLocation() {
        // no-op
    }
    
    func stopUpdatingLocation() {
        // no-op
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
}

extension ManualLocationManager: CLLocationManagerDelegate {
    
    @nonobjc func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager(self, didUpdate: locations)
    }
}
