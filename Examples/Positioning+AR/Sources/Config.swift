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

enum ARGlobals {
    // Saint Roch
    static let origin = Coordinate(latitude: 43.60484182694762, longitude: 3.880688039628751, level: 0) // entrance
}

enum PreferencesKey: String {
    case positioningVersion,
         geoARVersion
}

func customKeysAndValues() -> [String: Any] {
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .positioningVersion: Bundle.positioningVPSARKit.version,
        .geoARVersion: Bundle.geoAR.version
    ]
    
    let dict = Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
    return dict
}
