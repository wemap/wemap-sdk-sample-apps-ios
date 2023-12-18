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
        19158 // TODO: Modify this value with your own map id
    }
    
    static var token: String {
        "GUHTU6TYAWWQHUSR5Z5JZNMXX" // TODO: Modify this value with your own wemap token
    }
    
    static var polestarApiKey: String {
        fatalError("Specify polestarApiKey and remove fatalError")
    }
    
    static var vpsEndpoint: String {
        fatalError("Specify vpsEndpoint and remove fatalError")
    }
}
