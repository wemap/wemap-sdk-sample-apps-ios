//
//  GlobalItineraryOptions.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 16/07/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import WemapMapSDK

var globalItineraryOptions: ItineraryOptions {
    .init(
        indoorLine: .init(color: .systemBlue),
        projectionLine: .init(width: 5, color: .lightGray, dashPattern: .init(forConstantValue: [0.5, 2])),
        outdoorLine: .init(width: 10, color: .darkGray)
    )
}
