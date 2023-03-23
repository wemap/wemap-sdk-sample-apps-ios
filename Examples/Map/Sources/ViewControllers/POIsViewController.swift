//
//  POIsViewController.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import UIKit
import Mapbox
import WemapCoreSDK
import WemapMapSDK

final class POIsViewController: UIViewController {
    
    @IBOutlet var levelControl: UISegmentedControl!
    
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
        
        map.mapDelegate = self
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
}

extension POIsViewController: WemapMapViewDelegate {
    
    func map(_ map: MapView, didTouchPointOfInterest poi: PointOfInterest) {
        debugPrint(#function)
    }
    
    func map(_ map: MapView, didTouchItinerary itinerary: Itinerary) {
        debugPrint(#function)
    }
    
    func map(_ map: MapView, didTouchFeature feature: MGLFeature) {
        
        if let externalId = feature.attribute(forKey: "externalId") as? String,
           let consumerValue = consumerData.first(where: { $0.externalID == externalId }) {
            
            let annotation = MGLPointAnnotation()
            annotation.coordinate = consumerValue.coordinate
            annotation.title = consumerValue.name
            
            let toast = ToastHelper.showToast(
                message: "Touched consumer feature with name - \(consumerValue.name). Feature - \(feature)",
                onView: view,
                hideDelay: 5) {
                    map.removeAnnotation(annotation)
                }
            
            let padding = UIEdgeInsets(top: 0, left: 0, bottom: toast.frame.height, right: 0)
            
            map.addAnnotation(annotation)
            map.showAnnotations([annotation], edgePadding: padding, animated: true, completionHandler: nil)
            
            debugPrint("toast frame - \(toast.frame)")
            return
        }
        
        ToastHelper.showToast(
            message: "Touched feature - \(feature)",
            onView: view,
            hideDelay: 5
        )
    }
}

extension POIsViewController: BuildingManagerDelegate {
    
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
