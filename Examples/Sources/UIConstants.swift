//
//  UIConstants.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 18/12/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation

enum UIConstants {
    
    enum Delay {
        static let short: TimeInterval = 5
        static let long: TimeInterval = 10
    }
    
    enum Inset {
        static let top: CGFloat = -200
        static let mid: CGFloat = -150

        /**
         How far a control sits from the edge of what it floats over, on every screen of every example that
         places one itself.

         It is `16`, the platform's own minimum layout margin for a compact width, so the examples agree
         with each other and with the system's own spacing.
         */
        static let overlay: CGFloat = 16
    }
}
