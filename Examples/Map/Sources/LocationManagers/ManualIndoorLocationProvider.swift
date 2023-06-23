//
//  ManualIndoorLocationProvider.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 13/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Mapbox
import WemapCoreSDK
import WemapMapSDK

class ManualIndoorLocationProvider: RxObject, IndoorLocationProvider {
    
    weak var indoorDelegate: IndoorLocationProviderDelegate?
    
    var lastCoordinate: Coordinate?
    
    init(map: MapView) {
        super.init()
        
        let longPress = UILongPressGestureRecognizer()
        
        longPress.rx
            .event
            .filter { $0.state == .ended }
            .subscribe(onNext: { [unowned self] event in
                let coord = map.convert(event.location(in: map), toCoordinateFrom: map)
                let location = CLLocation(coordinate: coord, altitude: 8, horizontalAccuracy: .infinity, verticalAccuracy: .infinity, timestamp: .init())
                let coordinate = Coordinate(location: location, levels: [0])
                lastCoordinate = coordinate
                indoorDelegate?.locationProvider(self, didUpdateLocation: coordinate)
            }).disposed(by: disposeBag)
        
        map.addGestureRecognizer(longPress)
    }
    
    func startUpdatingLocation() {
        // no-op
    }
    
    func stopUpdatingLocation() {
        // no-op
    }
}
