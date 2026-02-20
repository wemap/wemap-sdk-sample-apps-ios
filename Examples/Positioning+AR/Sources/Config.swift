//
//  Config.swift
//  Positioning+ARExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK
import WemapGeoARSDK
import WemapPositioningSDKVPSARKit

enum PreferencesKey: String {
    case positioningVersion,
         geoARVersion
}

func customKeysAndValues() -> [String: Any] {
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .positioningVersion: Bundle.positioningVPSARKit.version,
        .geoARVersion: Bundle.geoAR.version
    ]
    
    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
