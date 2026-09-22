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
    /** versions */
    case mapVersion,
         mapLibreVersion,
         // App constants
         simulatorDeviationRange,
         // Core constants
         itineraryRecalculationEnabled,
         userLocationProjectionOnItineraryEnabled,
         userLocationProjectionOnGraphEnabled,
         pointsOfInterestLoadingTimeoutSeconds,
         // Map constants
         switchLevelsAutomaticallyOnUserMovements,
         staleStateTimeout,
         // Global navigation options
         arrivedDistanceThreshold,
         userPositionThreshold,
         navigationRecalculationTimeInterval
}

func makeSessionConfig() -> SessionConfig {
    .init(
        itineraryRecalculationEnabled: UserDefaults.bool(
            forKey: .itineraryRecalculationEnabled, defaultValue: true
        ),
        userLocationProjectionOnItineraryEnabled: UserDefaults.bool(
            forKey: .userLocationProjectionOnItineraryEnabled, defaultValue: true
        ),
        userLocationProjectionOnGraphEnabled: UserDefaults.bool(
            forKey: .userLocationProjectionOnGraphEnabled, defaultValue: false
        ),
        pointsOfInterestLoadingTimeout: .seconds(UserDefaults.int(
            forKey: .pointsOfInterestLoadingTimeoutSeconds, defaultValue: 10
        ))
    )
}

func makeMapViewConfig() -> MapViewConfig {
    .init(
        switchLevelsAutomaticallyOnUserMovements: UserDefaults.bool(
            forKey: .switchLevelsAutomaticallyOnUserMovements, defaultValue: true
        ),
        staleStateTimeout: .seconds(UserDefaults.int(forKey: .staleStateTimeout, defaultValue: 5))
    )
}

func sdkVersions() -> [String: Any] {

    CommonAppConstants.simulatorDeviationRange = UserDefaults
        .double(forKey: .simulatorDeviationRange, defaultValue: CommonAppConstants.simulatorDeviationRange)

    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version
    ]

    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
