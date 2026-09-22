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
         geoARVersion,
         navigationVisibilityDistance,
         // Core constants
         pointsOfInterestLoadingTimeoutSeconds
}

func makeSessionConfig() -> SessionConfig {
    .init(pointsOfInterestLoadingTimeout: .seconds(UserDefaults.int(
        forKey: .pointsOfInterestLoadingTimeoutSeconds, defaultValue: 10
    )))
}

func makeGeoARViewConfig() -> GeoARViewConfig {
    // Use nil when the value equals the default, so the map configuration can provide it instead.
    let rawDistance = UserDefaults.double(forKey: .navigationVisibilityDistance, defaultValue: 10)
    return .init(navigationVisibilityDistance: rawDistance == 10 ? nil : rawDistance)
}

func sdkVersions() -> [String: Any] {
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .positioningVersion: Bundle.positioningVPSARKit.version,
        .geoARVersion: Bundle.geoAR.version
    ]

    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
