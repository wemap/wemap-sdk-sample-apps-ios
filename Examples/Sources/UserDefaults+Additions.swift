//
//  UserDefaults+Additions.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 15/11/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation

extension UserDefaults {
    
    static func bool(forKey key: PreferencesKey) -> Bool {
        standard.bool(forKey: key.rawValue)
    }
    
    static func value(forKey key: PreferencesKey) -> Any? {
        standard.value(forKey: key.rawValue)
    }
    
    static func double(forKey key: PreferencesKey, defaultValue: Double) -> Double {
        UserDefaults.value(forKey: key) != nil ? standard.double(forKey: key.rawValue) : defaultValue
    }
}
