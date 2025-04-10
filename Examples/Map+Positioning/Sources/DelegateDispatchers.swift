//
//  DelegateDispatchers.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 27/03/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import WemapMapSDK
import WemapPositioningSDKVPSARKit

final class VPSDelegateDispatcher: VPSARKitLocationSourceDelegate {
    
    weak var primary: VPSARKitLocationSourceDelegate?
    weak var secondary: VPSARKitLocationSourceDelegate?
    
    private var delegates: [VPSARKitLocationSourceDelegate?] {
        [primary, secondary]
    }
    
    func locationSource(_ locationSource: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
        for delegate in delegates {
            delegate?.locationSource(locationSource, didChangeState: state)
        }
    }
    
    func locationSource(_ locationSource: VPSARKitLocationSource, didChangeScanStatus status: VPSARKitLocationSource.ScanStatus) {
        for delegate in delegates {
            delegate?.locationSource(locationSource, didChangeScanStatus: status)
        }
    }
}

final class LocationManagerDelegateDispatcher: UserLocationManagerDelegate {
    
    weak var primary: UserLocationManagerDelegate?
    weak var secondary: UserLocationManagerDelegate?
    
    private var delegates: [UserLocationManagerDelegate?] {
        [primary, secondary]
    }
    
    func locationManager(_ manager: UserLocationManager, didFailWithError error: any Error) {
        for delegate in delegates {
            delegate?.locationManager(manager, didFailWithError: error)
        }
    }
}
