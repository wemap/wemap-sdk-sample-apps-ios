//
//  Config.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import WemapMapSDK
import WemapPositioningSDK
import WemapPositioningSDKVPSARKit

enum PreferencesKey: String {
    // versions
    case mapVersion,
         positioningVersion,
         mapLibreVersion,
         // constants
         switchLevelsAutomaticallyOnUserMovements,
         // Global navigation options
         arrivedDistanceThreshold,
         userPositionThreshold,
         navigationRecalculationTimeInterval
}

func customKeysAndValues() -> [String: Any] {
    
    MapConstants.switchLevelsAutomaticallyOnUserMovements = UserDefaults
        .bool(forKey: .switchLevelsAutomaticallyOnUserMovements, defaultValue: MapConstants.switchLevelsAutomaticallyOnUserMovements)
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version,
        .positioningVersion: Bundle.positioning.version
    ]
    
    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
