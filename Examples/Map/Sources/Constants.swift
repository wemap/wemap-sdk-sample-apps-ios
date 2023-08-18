//
//  Constants.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 16/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import CoreLocation
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
        fatalError("Specify polestarApiKey and remove fatalError")
    }
    
    static var globalNavigationOptions: NavigationOptions {
        NavigationOptions(
            itineraryOptions: .init(color: .cyan, projectionOptions: .init(width: 5, color: .lightGray)),
            userTrackingMode: .followWithHeading
        )
    }
}
