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
    case mapVersion,
         positioningVersion,
         mapLibreVersion,
         cameraImageMaxSizeSmallerSide
}

func customKeysAndValues() -> [String: Any] {
    
    VPSARKitConstants.cameraImageMaxSizeSmallerSide = UserDefaults
        .double(forKey: .cameraImageMaxSizeSmallerSide, defaultValue: VPSARKitConstants.cameraImageMaxSizeSmallerSide)
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version,
        .positioningVersion: Bundle.positioning.version
    ]
    
    let dict = Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
    return dict
}
