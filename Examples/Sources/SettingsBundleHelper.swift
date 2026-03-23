//
//  SettingsBundleHelper.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK

private enum GlobalPreferencesKey: String {
    case appVersion,
         buildNumber,
         coreVersion
}

enum SettingsBundleHelper {
    
    static func applySettings(customKeysAndValues: [String: Any] = [:]) {
        
        let defaults = UserDefaults.standard
        
        defaults.setValuesForKeys(customKeysAndValues)

        let commonKeysAndValues: [GlobalPreferencesKey: Any] = [
            .appVersion: Bundle.main.version,
            .buildNumber: Bundle.main.build,
            .coreVersion: Bundle.core.version
        ]

        let dict = Dictionary(uniqueKeysWithValues: commonKeysAndValues.map { ($0.rawValue, $1) })
        defaults.setValuesForKeys(dict)
    }
}
