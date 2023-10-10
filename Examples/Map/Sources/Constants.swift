//
//  Constants.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 16/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK
import WemapMapSDK

enum Constants {
    
    static var mapID: Int {
        fatalError("Specify mapID and remove fatalError")
    }
    
    static var token: String {
        fatalError("Specify token and remove fatalError")
    }
    
    static var polestarApiKey: String {
        fatalError("Specify token and remove fatalError")
    }
    
    static var globalNavigationOptions: NavigationOptions {
        NavigationOptions(
            itineraryOptions: .init(color: .cyan, projectionOptions: .init(width: 5, color: .lightGray)),
            userTrackingMode: .followWithHeading
        )
    }
}

enum UIConstants {
    
    enum Delay {
        static let short: TimeInterval = 5
        static let long: TimeInterval = 10
    }
    
    enum Inset {
        static let top: CGFloat = -200
        static let mid: CGFloat = -150
    }
}

extension UserDefaults {
    
    static func double(forKey key: PreferencesKey, defaultValue: Double) -> Double {
        UserDefaults.value(forKey: key) != nil ? standard.double(forKey: key.rawValue) : defaultValue
    }
}
