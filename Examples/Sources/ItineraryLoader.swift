//
//  ItineraryLoader.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 09/05/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK

enum ItineraryLoader {
    
    static func loadFromGeoJSON() -> Itinerary? {
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: "geoJsonItinerary", withExtension: "json")!)
            let geoJsonItinerary = try JSONDecoder().decode(GeoJsonItinerary.self, from: data)
            return geoJsonItinerary.toItinerary()
        } catch {
            debugPrint("Failed to load geo itinerary from file with error - \(error)")
            return nil
        }
    }
}
