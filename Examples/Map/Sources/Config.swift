//
//  Config.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK
import WemapMapSDK

enum PreferencesKey: String {
    // versions
    case mapVersion,
         mapLibreVersion,
         // constants
         switchLevelsAutomaticallyOnUserMovements,
         // Global navigation options
         stopDistanceThreshold,
         userPositionThreshold,
         navigationRecalculationTimeInterval
}

func customKeysAndValues() -> [String: Any] {

    MapConstants.switchLevelsAutomaticallyOnUserMovements = UserDefaults
        .bool(forKey: .switchLevelsAutomaticallyOnUserMovements, defaultValue: MapConstants.switchLevelsAutomaticallyOnUserMovements)
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version
    ]
    
    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
