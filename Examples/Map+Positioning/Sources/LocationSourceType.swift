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
         systemDefault,
         polestar,
         polestarEmulator
         
    var name: String {
        switch self {
        case .vps: "VPS"
        case .simulator: "Simulator"
        case .systemDefault: "System Default"
        case .polestar: "Polestar"
        case .polestarEmulator: "Polestar Emulator"
        }
    }
}
