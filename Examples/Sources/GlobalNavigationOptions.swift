//
//  GlobalNavigationOptions.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 03/07/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK

var globalNavigationOptions: NavigationOptions {
    .init(
        arrivedDistanceThreshold: UserDefaults.double(forKey: .arrivedDistanceThreshold, defaultValue: 15),
        userPositionThreshold: UserDefaults.double(forKey: .userPositionThreshold, defaultValue: 25),
        navigationRecalculationTimeInterval: UserDefaults.double(forKey: .navigationRecalculationTimeInterval, defaultValue: 5)
    )
}
