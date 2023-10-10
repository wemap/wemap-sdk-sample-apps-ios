//
//  LocationSourceType.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 31/08/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import WemapCoreSDK
import WemapMapSDK

enum LocationSourceType: Int, CaseIterable {
    
    case simulator,
         polestar,
         systemDefault,
         polestarEmulator
         
    var name: String {
        switch self {
        case .simulator: return "Simulator"
        case .polestar: return "Polestar"
        case .systemDefault: return "System Default"
        case .polestarEmulator: return "Polestar Emulator"
        }
    }
    
    var source: LocationSource? {
        switch self {
        case .simulator: return LocationSourceSimulator()
        case .polestar: return PolestarLocationSource(apiKey: Constants.polestarApiKey)
        case .systemDefault: return nil
        case .polestarEmulator: return PolestarLocationSource(apiKey: "emulator")
        }
    }
}
