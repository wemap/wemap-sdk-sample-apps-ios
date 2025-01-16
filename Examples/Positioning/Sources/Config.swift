//
//  Config.swift
//  PositioningExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import WemapPositioningSDK

enum PreferencesKey: String {
    case positioningVersion
}

func customKeysAndValues() -> [String: Any] {
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .positioningVersion: Bundle.positioning.version
    ]
    
    let dict = Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
    return dict
}
