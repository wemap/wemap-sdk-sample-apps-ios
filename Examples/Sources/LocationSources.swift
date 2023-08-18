//
//  LocationSources.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 31/07/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import WemapCoreSDK

enum LocationSourceType: Int, CaseIterable {
    case polestar,
         polestarEmulator,
         simulator
    
    var name: String {
        switch self {
        case .polestar: return "Polestar Location Source"
        case .polestarEmulator: return "Polestar Emulator"
        case .simulator: return "Simulator Location Source"
        }
    }
}
