//
//  SamplesTableViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 23/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK

class SamplesTableViewController: UITableViewController {

    var mapData: MapData!
    var locationSourceType: LocationSourceType!
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {

        guard let mapData else {
            fatalError("You have to successfully retrieve style URL first")
        }
        
        let map = segue.destination as! MapViewController // swiftlint:disable:this force_cast
        map.mapData = mapData
        map.locationSourceType = locationSourceType
    }
}
