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

func customKeysAndValues() -> [String: Any] {
    
    // Core
    CoreConstants.userLocationProjectionOnItineraryEnabled = UserDefaults
        .bool(forKey: .userLocationProjectionOnItineraryEnabled, defaultValue: CoreConstants.userLocationProjectionOnItineraryEnabled)
    
    CoreConstants.userLocationProjectionOnGraphEnabled = UserDefaults
        .bool(forKey: .userLocationProjectionOnGraphEnabled, defaultValue: CoreConstants.userLocationProjectionOnGraphEnabled)
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .positioningVersion: Bundle.positioningVPSARKit.version
    ]
    
    let dict = Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
    return dict
}
