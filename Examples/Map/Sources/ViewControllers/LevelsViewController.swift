//
//  LevelsViewController.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//
// swiftlint:disable force_try force_cast

import Mapbox
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class LevelsViewController: UIViewController {
    
    @IBOutlet var levelControl: UISegmentedControl!
    
    private lazy var indoorProvider = PolestarIndoorLocationProvider()
    
    private lazy var consumerData: [ConsumerData] = {
        let dataURL = Bundle.main.url(forResource: "consumer_data", withExtension: "json")!
        let data = try! Data(contentsOf: dataURL)
        return try! JSONDecoder().decode([ConsumerData].self, from: data)
    }()
    
    private var map: MapView {
        view as! MapView
    }
    
    private var buildingManager: BuildingManager {
        map.buildingManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.backgroundColor = .white
        
        switch Constants.locationProvider {
        case .systemDefault:
            break
        case .customCLLocationManager:
            map.locationManager = CustomLocationManager()
        case .polestar:
            map.locationManager = indoorProvider
            map.indoorLocationProvider = indoorProvider
        case .manual:
            map.locationManager = ManualLocationManager(map: map)
        }
        
        debugPrint("using \(Constants.locationProvider.rawValue) location provider")
        
        buildingManager.delegate = self
        
        levelControl.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let initialBounds = map.initialBounds {
            let camera = map.cameraThatFitsCoordinateBounds(initialBounds)
            map.setCamera(camera, animated: true)
        }
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func levelChanged(_ sender: UISegmentedControl) {
        debugPrint("level changed - \(sender.selectedSegmentIndex)")
        buildingManager.focusedBuilding!.activeLevelIndex = sender.selectedSegmentIndex
    }
    
    @IBAction func firstTouched() {
        let data = consumerData[0]
        if activateLevel(data.level) {
            addAnnotation(for: data)
        }
    }
    
    @IBAction func secondTouched() {
        let data = consumerData[1]
        if activateLevel(data.level) {
            addAnnotation(for: data)
        }
    }
    
    private func activateLevel(_ id: Float) -> Bool {
        
        guard let building = buildingManager.focusedBuilding,
              let desiredLevel = building.levels.first(where: { $0.id == id }) else {
            
            let buildingDescription = buildingManager.focusedBuilding?.debugDescription ?? "no focused building"
            debugPrint("Failed to find desired level with id - \(id), in building - \(buildingDescription)")
            return false
        }
        
        if building.activeLevel == desiredLevel {
            debugPrint("Level already activated - \(desiredLevel), in building - \(building)")
            return true
        }
        
        let previousLevel = building.activeLevel
        building.activeLevel = desiredLevel
        
        guard previousLevel != building.activeLevel else {
            debugPrint("Failed to activate level - \(desiredLevel), in building - \(building)")
            return false
        }
        
        levelControl.selectedSegmentIndex = building.activeLevelIndex
        
        return true
    }
    
    private func addAnnotation(for data: ConsumerData) {

        let annotation = MGLPointAnnotation()
        annotation.coordinate = data.coordinate
        annotation.title = data.name
        
        let toast = ToastHelper.showToast(
            message: "Add annnotation for consumer data - \(data)",
            onView: view,
            hideDelay: 5
        ) { [self] in
            map.removeAnnotation(annotation)
        }
        
        let padding = UIEdgeInsets(top: 0, left: 0, bottom: toast.frame.height, right: 0)
        
        map.addAnnotation(annotation)
        map.showAnnotations([annotation], edgePadding: padding, animated: true, completionHandler: nil)
    }
}

extension LevelsViewController: BuildingManagerDelegate {
    
    func map(_: MapView, didChangeLevel level: Level, ofBuilding building: Building) {
        debugPrint("\(#function) with \(level.id), of building \(building.name)")
        levelControl.selectedSegmentIndex = building.activeLevelIndex
    }
    
    func map(_: MapView, didFocusBuilding building: Building?) {
        
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

// swiftlint:enable force_try force_cast
