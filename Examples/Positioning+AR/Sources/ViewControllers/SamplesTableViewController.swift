//
//  SamplesTableViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 19/05/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK

class SamplesTableViewController: UITableViewController {
    
    var mapData: MapData!
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        
        guard let mapData else {
            fatalError("You have to successfully retrieve style URL first")
        }
        
        if let arController = segue.destination as? GeoARViewController {
            arController.mapData = mapData
        }

        guard let genericLSController = segue.destination as? GenericLSViewController else {
            return
        }

        genericLSController.locationSourceId = switch segue.identifier {
        case "Simulator": 0
        case "GPS": 1
        default: fatalError("Unknown segue identifier")
        }
    }
}
