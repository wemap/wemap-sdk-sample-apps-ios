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

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "VPS" && mapData.extras?.vpsEndpoint == nil {
            AlertFactory.presentInfoAlert(message: "This map(\(mapData.id)) is not compatible with VPS Location Source", on: self)
            if let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            return false
        }
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {

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
