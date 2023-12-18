//
//  LocationSourceType.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 31/07/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

enum LocationSourceType: Int, CaseIterable {
    
    case vps,
         simulator,
         polestar,
         systemDefault,
         polestarEmulator
         
    var name: String {
        switch self {
        case .simulator: "Simulator"
        case .polestar: "Polestar"
        case .systemDefault: "System Default"
        case .polestarEmulator: "Polestar Emulator"
        case .vps: "VPS"
        }
    }
}
