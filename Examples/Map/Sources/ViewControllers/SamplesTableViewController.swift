//
//  SamplesTableViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 23/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import RxSwift
import UIKit
import WemapMapSDK

class SamplesTableViewController: UITableViewController {

    var mapData: MapData?
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {

        guard let mapData else {
            fatalError("You have to successfully retrieve style URL first")
        }
        
        let map = segue.destination.view as! MapView // swiftlint:disable:this force_cast
        map.mapData = mapData
    }
}
