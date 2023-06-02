//
//  POIsViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//
// swiftlint:disable force_cast

import Mapbox
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class POIsViewController: UIViewController {
    
    private let maxBounds = MGLCoordinateBounds(
        sw: CLLocationCoordinate2D(latitude: 48.84045277048898, longitude: 2.371600716985739),
        ne: CLLocationCoordinate2D(latitude: 48.84811619854466, longitude: 2.377353558713054)
    )
    
    @IBOutlet var levelControl: UISegmentedControl!
    
    private var map: MapView {
        view as! MapView
    }
    
    private var buildingManager: BuildingManager {
        map.buildingManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // camera bounds can be specified even if they don't exist in MapData
//        map.cameraBounds = maxBounds
        map.mapDelegate = self
        buildingManager.delegate = self
        
        levelControl.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let initialBounds = map.mapData?.bounds {
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
    
    private func selectFeatureByWemapID(_ feature: MGLFeature) {
        
        guard let wemapId = feature.attribute(forKey: "wemapId") as? Int else {
            return debugPrint("Failed to selectFeatureByWemapID because wemapId attribute not found")
        }
            
        let centered = map.pointOfInterestManager.centerToPOI(id: wemapId, animated: true)
        
        debugPrint("\(centered ? "successfully centered" : "failed to center") to poi with id \(wemapId)")
        
        if centered {
            ToastHelper.showToast(
                message: "Touched consumer feature with id - \(wemapId). Feature - \(feature)",
                onView: view,
                hideDelay: 5
            ) { [self] in
                map.pointOfInterestManager.showPOI(id: wemapId)
            }
            
            map.pointOfInterestManager.hidePOI(id: wemapId)
        }
    }
    
    private func selectFeatureByPOI(_ feature: MGLFeature) {
        guard let wemapId = feature.attribute(forKey: "wemapId") as? Int else {
            return debugPrint("Failed to selectFeatureByWemapID because wemapId attribute not found")
        }
            
        guard let clickedPOI = map.pointOfInterestManager.getPOIs().first(where: { $0.id == wemapId }) else {
            return debugPrint("failed to find cached POI for feature - \(feature)")
        }
        
        let centered = map.pointOfInterestManager.centerToPOI(clickedPOI, animated: true)
        
        debugPrint("\(centered ? "successfully centered" : "failed to center") to poi with id \(wemapId)")
        
        if centered {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = clickedPOI.coordinate2D
            annotation.title = clickedPOI.name
            
            let toast = ToastHelper.showToast(
                message: "Touched consumer feature with name - \(clickedPOI.name). Feature - \(feature)",
                onView: view,
                hideDelay: 5
            ) { [self] in
                map.pointOfInterestManager.showPOI(poi: clickedPOI)
                map.removeAnnotation(annotation)
            }
            
            let padding = UIEdgeInsets(top: 0, left: 0, bottom: toast.frame.height, right: 0)
            
            map.addAnnotation(annotation)
            map.showAnnotations([annotation], edgePadding: padding, animated: true, completionHandler: nil)
            map.pointOfInterestManager.hidePOI(poi: clickedPOI)
        }
    }
}

extension POIsViewController: WemapMapViewDelegate {
    
    func map(_: MapView, didTouchPointOfInterest _: PointOfInterest) {
        debugPrint(#function)
    }
    
    func map(_: MapView, didTouchItinerary _: Itinerary) {
        debugPrint(#function)
    }
    
    func map(_: MapView, didTouchFeature feature: MGLFeature) {
        
        selectFeatureByWemapID(feature)
//        selectFeatureByPOI(feature)
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

// swiftlint:enable force_cast
