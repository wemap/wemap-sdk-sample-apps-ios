//
//  Config.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapMapSDK

enum PreferencesKey: String {
    case mapVersion,
         mapLibreVersion,
         indoorMinZoomLevel,
         visualDebuggingEnabled,
         switchLevelsAutomaticallyOnUserMovements,
         itineraryRecalculationEnabled,
         userLocationProjectionOnItineraryEnabled,
         stopDistanceThreshold,
         userPositionThreshold,
         navigationRecalculationTimeInterval
}

func customKeysAndValues() -> [String: Any] {
    
    let minZoomLevel = UserDefaults.double(forKey: .indoorMinZoomLevel, defaultValue: 0)
    if minZoomLevel != 0 {
        MapConstants.Indoor.minZoomLevel = minZoomLevel
    }
    
    MapConstants.visualDebuggingEnabled = UserDefaults.bool(forKey: .visualDebuggingEnabled)
    
    if UserDefaults.value(forKey: .switchLevelsAutomaticallyOnUserMovements) != nil {
        MapConstants.switchLevelsAutomaticallyOnUserMovements = UserDefaults.bool(forKey: .switchLevelsAutomaticallyOnUserMovements)
    }
    
    if UserDefaults.value(forKey: .itineraryRecalculationEnabled) != nil {
        MapConstants.itineraryRecalculationEnabled = UserDefaults.bool(forKey: .itineraryRecalculationEnabled)
    }
    
    if UserDefaults.value(forKey: .userLocationProjectionOnItineraryEnabled) != nil {
        MapConstants.userLocationProjectionOnItineraryEnabled = UserDefaults.bool(forKey: .userLocationProjectionOnItineraryEnabled)
    }
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version
    ]
    
    let dict = Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
    return dict
}

extension UserDefaults {
    
    static func bool(forKey key: PreferencesKey) -> Bool {
        standard.bool(forKey: key.rawValue)
    }
    
    static func value(forKey key: PreferencesKey) -> Any? {
        standard.value(forKey: key.rawValue)
    }
}
