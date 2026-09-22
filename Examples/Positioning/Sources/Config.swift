//
//  Config.swift
//  PositioningExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK
import WemapPositioningSDKVPSARKit

enum PreferencesKey: String {
    case positioningVersion,
         // Core constants
         userLocationProjectionOnItineraryEnabled,
         userLocationProjectionOnGraphEnabled
}

func makeSessionConfig() -> SessionConfig {
    .init(
        userLocationProjectionOnItineraryEnabled: UserDefaults.bool(
            forKey: .userLocationProjectionOnItineraryEnabled, defaultValue: true
        ),
        userLocationProjectionOnGraphEnabled: UserDefaults.bool(
            forKey: .userLocationProjectionOnGraphEnabled, defaultValue: false
        )
    )
}

func sdkVersions() -> [String: Any] {
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .positioningVersion: Bundle.positioningVPSARKit.version
    ]

    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
