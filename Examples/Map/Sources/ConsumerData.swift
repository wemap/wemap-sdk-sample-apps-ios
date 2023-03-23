//
//  ConsumerData.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import CoreLocation

struct ConsumerData: Decodable {
    let level: Float
    let externalID: String
    let coordinate: CLLocationCoordinate2D
    let name: String
}
