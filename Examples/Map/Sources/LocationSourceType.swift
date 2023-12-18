//
//  LocationSourceType.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 31/08/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

enum LocationSourceType: Int, CaseIterable {
    
    case simulator,
         polestar,
         systemDefault,
         polestarEmulator
         
    var name: String {
        switch self {
        case .simulator: "Simulator"
        case .polestar: "Polestar"
        case .systemDefault: "System Default"
        case .polestarEmulator: "Polestar Emulator"
        }
    }
}
