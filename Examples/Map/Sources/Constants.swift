//
//  Constants.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 16/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation

enum Constants {
    
    static var mapID: Int {
        fatalError("Specify mapID and remove fatalError")
    }
    
    static var token: String {
        fatalError("Specify token and remove fatalError")
    }
    
    static var locationProvider = LocationProvider.systemDefault
    
    enum LocationProvider: String {
        case systemDefault, manual, polestar
    }
}
