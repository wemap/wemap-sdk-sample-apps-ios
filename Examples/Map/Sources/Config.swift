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
         itineraryRecalculationEnabled,
         userLocationProjectionOnItineraryEnabled,
         // Global navigation options
         arrivedDistanceThreshold,
         userPositionThreshold,
         navigationRecalculationTimeInterval
}

func customKeysAndValues() -> [String: Any] {
    
    MapConstants.switchLevelsAutomaticallyOnUserMovements = UserDefaults
        .bool(forKey: .switchLevelsAutomaticallyOnUserMovements, defaultValue: MapConstants.switchLevelsAutomaticallyOnUserMovements)
    
    CoreConstants.itineraryRecalculationEnabled = UserDefaults
        .bool(forKey: .itineraryRecalculationEnabled, defaultValue: CoreConstants.itineraryRecalculationEnabled)
    
    CoreConstants.userLocationProjectionOnItineraryEnabled = UserDefaults
        .bool(forKey: .userLocationProjectionOnItineraryEnabled, defaultValue: CoreConstants.userLocationProjectionOnItineraryEnabled)
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version
    ]
    
    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
