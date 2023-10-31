//
//  LocationSourceType.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 31/07/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDK

enum LocationSourceType: Int, CaseIterable {
    
    case vps,
         simulator,
         polestar,
         systemDefault,
         polestarEmulator
         
    var name: String {
        switch self {
        case .simulator: return "Simulator"
        case .polestar: return "Polestar"
        case .systemDefault: return "System Default"
        case .polestarEmulator: return "Polestar Emulator"
        case .vps: return "VPS"
        }
    }
}
