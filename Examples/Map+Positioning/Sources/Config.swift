//
//  Config.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKVPSARKit

enum PreferencesKey: String {

    case enableHapticFeedback,
         useWheelchair,
         // versions
         mapVersion,
         mapLibreVersion,
         positioningVersion,
         // Core constants
         itineraryRecalculationEnabled,
         userLocationProjectionOnItineraryEnabled,
         userLocationProjectionOnGraphEnabled,
         // Map constants
         switchLevelsAutomaticallyOnUserMovements,
         staleTimeoutMilliseconds,
         // VPS constants
         slowConnectionSeconds,
         // Global navigation options
         arrivedDistanceThreshold,
         userPositionThreshold,
         navigationRecalculationTimeInterval
}

enum AppConstants {
    static var enableHapticFeedback: Bool = true
    static var useWheelchair: Bool = false
}

func customKeysAndValues() -> [String: Any] {

    AppConstants.enableHapticFeedback = UserDefaults
        .bool(forKey: .enableHapticFeedback, defaultValue: AppConstants.enableHapticFeedback)

    AppConstants.useWheelchair = UserDefaults
        .bool(forKey: .useWheelchair, defaultValue: AppConstants.useWheelchair)

    // MARK: - Core

    CoreConstants.itineraryRecalculationEnabled = UserDefaults
        .bool(forKey: .itineraryRecalculationEnabled, defaultValue: CoreConstants.itineraryRecalculationEnabled)
    
    CoreConstants.userLocationProjectionOnItineraryEnabled = UserDefaults
        .bool(forKey: .userLocationProjectionOnItineraryEnabled, defaultValue: CoreConstants.userLocationProjectionOnItineraryEnabled)
    
    CoreConstants.userLocationProjectionOnGraphEnabled = UserDefaults
        .bool(forKey: .userLocationProjectionOnGraphEnabled, defaultValue: CoreConstants.userLocationProjectionOnGraphEnabled)
    
    // MARK: - Map

    MapConstants.switchLevelsAutomaticallyOnUserMovements = UserDefaults
        .bool(forKey: .switchLevelsAutomaticallyOnUserMovements, defaultValue: MapConstants.switchLevelsAutomaticallyOnUserMovements)
    
    MapConstants.staleTimeoutMilliseconds = UserDefaults
        .int(forKey: .staleTimeoutMilliseconds, defaultValue: MapConstants.staleTimeoutMilliseconds)

    // MARK: - VPS

    VPSARKitConstants.slowConnectionSeconds = UserDefaults
        .int(forKey: .slowConnectionSeconds, defaultValue: VPSARKitConstants.slowConnectionSeconds)

    // MARK: - Versions

    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version,
        .positioningVersion: Bundle.positioningVPSARKit.version
    ]
    
    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
