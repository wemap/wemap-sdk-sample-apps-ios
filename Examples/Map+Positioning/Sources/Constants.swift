//
//  Constants.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 31/08/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK

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
}

enum UIConstants {
    
    enum Delay {
        static let short: TimeInterval = 5
        static let long: TimeInterval = 10
    }
    
    enum Inset {
        static let top: CGFloat = -200
        static let mid: CGFloat = -150
    }
}
