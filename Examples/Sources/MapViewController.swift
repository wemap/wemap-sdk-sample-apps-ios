//
//  MapViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 01/08/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import WemapCoreSDK
import WemapMapSDK
import UIKit

class MapViewController: UIViewController, BuildingManagerDelegate {
    
    var mapData: MapData!
    var locationSourceType: LocationSourceType!
    
    @IBOutlet var levelControl: UISegmentedControl!
    
//    private let maxBounds = MGLCoordinateBounds(
//        sw: CLLocationCoordinate2D(latitude: 48.84045277048898, longitude: 2.371600716985739),
//        ne: CLLocationCoordinate2D(latitude: 48.84811619854466, longitude: 2.377353558713054)
//    )
    
    var map: MapView {
        view as! MapView // swiftlint:disable:this force_cast
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.mapData = mapData
        
        let source: LocationSource
        switch locationSourceType {
        case .polestar: source = PolestarLocationSource(apiKey: Constants.polestarApiKey)
        case .polestarEmulator: source = PolestarLocationSource(apiKey: "emulator")
        case .simulator: source = LocationSourceSimulator()
        default: fatalError("Unexpected Location Source Type")
        }
        map.userLocationManager.locationSource = source
        
        // camera bounds can be specified even if they don't exist in MapData
//        map.cameraBounds = maxBounds
        map.buildingManager.delegate = self
        
        levelControl.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let initialBounds = map.mapData?.bounds {
            let camera = map.cameraThatFitsCoordinateBounds(initialBounds)
            map.setCamera(camera, animated: true)
        }
    }
    
    @IBAction func levelChanged(_ sender: UISegmentedControl) {
        debugPrint("level changed - \(sender.selectedSegmentIndex)")
        map.buildingManager.focusedBuilding!.activeLevelIndex = sender.selectedSegmentIndex
    }

    // MARK: BuildingManagerDelegate
    
    @objc func map(_: MapView, didChangeLevel level: Level, ofBuilding building: Building) {
        debugPrint("\(#function) with \(level.id), of building \(building.name)")
        levelControl.selectedSegmentIndex = building.activeLevelIndex
    }
    
    @objc func map(_: MapView, didFocusBuilding building: Building?) {
        
        debugPrint("\(#function) with building \(building?.name ?? "nil")")
        
        guard let building else {
            levelControl.isHidden = true
            return
        }
        
        levelControl.removeAllSegments()
        let enumeratedLevels = building.levels.enumerated()
        for (index, level) in enumeratedLevels {
            levelControl.insertSegment(withTitle: level.shortName, at: index, animated: true)
        }
        levelControl.selectedSegmentIndex = building.activeLevelIndex
        levelControl.isEnabled = true
        levelControl.isHidden = false
    }
}
