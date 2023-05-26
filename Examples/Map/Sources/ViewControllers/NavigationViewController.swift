//
//  NavigationViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//
// swiftlint:disable force_cast

import Mapbox
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class NavigationViewController: UIViewController {
    
    @IBOutlet var levelControl: UISegmentedControl!
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var removeUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!
    
    private let disposeBag = DisposeBag()
    // you can use simulator to generate locations along the itinerary
    private let simulator = IndoorLocationProviderSimulator(options: SimulationOptions(inLoop: true))
    
    private var map: MapView {
        view as! MapView
    }
    
    private var userCreatedAnnotations: [MGLAnnotation] {
        map.annotations?
            .filter { $0.title == "user-created" } ?? []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.buildingManager.delegate = self
        map.mapDelegate = self
        
        map.locationManager = simulator
        map.indoorLocationProvider = simulator
        map.navigationManager.delegate = self
        
        levelControl.isHidden = true
        
        createLongPressGestureRecognizer()
        
        map.userTrackingMode = .followWithHeading
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ToastHelper.showToast(message: "Create 1 or 2 annotations by long press on the map to be able to start navigation. " +
            "1 annotation to start from user location. 2 annotations to start from custom location", onView: view, hideDelay: 5)
        
        if let initialBounds = map.mapData?.bounds {
            let camera = map.cameraThatFitsCoordinateBounds(initialBounds)
            map.setCamera(camera, animated: true)
        }
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    private func createLongPressGestureRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        map.addGestureRecognizer(longPress)
    }
    
    @objc private func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        guard userCreatedAnnotations.count < 2 else {
            ToastHelper.showToast(message: "You already created 2 annotations. Remove old ones to be able to add new", onView: view)
            return
        }
        let coord = map.convert(gesture.location(in: map), toCoordinateFrom: map)
        let point = MGLPointAnnotation()
        point.coordinate = coord
        point.title = "user-created"
        map.addAnnotation(point)
        updateStartNavigationButtons()
        removeUserCreatedAnnotationsButton.isEnabled = true
    }
    
    @IBAction func levelChanged(_ sender: UISegmentedControl) {
        debugPrint("level changed - \(sender.selectedSegmentIndex)")
        map.buildingManager.focusedBuilding!.activeLevelIndex = sender.selectedSegmentIndex
    }
    
    @IBAction func startNavigationFromUserLocation() {
        startNavigationButton.isEnabled = false
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = false
        
        let options = NavigationOptions(itineraryOptions: ItineraryOptions(color: .magenta))
        
        let to = userCreatedAnnotations.first!
        
        let destination = Coordinate(coordinate2D: to.coordinate, levels: [0])
        
        map.navigationManager
            .startNavigation(to: destination, options: options)
            .subscribe(
                onSuccess: { [unowned self] _ in
                    debugPrint("Navigation started successfully")
                    stopNavigationButton.isEnabled = true
                },
                onFailure: { [unowned self] error in
                    debugPrint("Failed to start navigation with error - \(error)")
                    updateStartNavigationButtons()
                    ToastHelper.showToast(
                        message: "Failed to start navigation from user position to - \(destination) with error - \(error)",
                        onView: view,
                        hideDelay: 10
                    )
                }
            ).disposed(by: disposeBag)
    }
    
    @IBAction func stopNavigation() {
        let result = map.navigationManager.stopNavigation()
        switch result {
        case let .success(itinerary):
            updateStartNavigationButtons()
            stopNavigationButton.isEnabled = false
            simulator.reset()
            navigationInfo.isHidden = true
            navigationInfo.text = nil
            debugPrint("Navigation stopped successfully. Itinerary - \(itinerary)")
        case let .failure(error):
            debugPrint("Failed to stop navigation with error - \(error)")
            ToastHelper.showToast(
                message: "Failed to stop navigation with error - \(error)",
                onView: view,
                hideDelay: 10
            )
        }
    }
    
    @IBAction func startNavigationFromUserCreatedAnnotations() {
        startNavigationButton.isEnabled = false
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = false
        
        let options = NavigationOptions(
            itineraryOptions: ItineraryOptions(color: .cyan),
            userTrackingMode: .followWithHeading
        )
        
        let from = userCreatedAnnotations[0]
        let to = userCreatedAnnotations[1]
        
        let origin = Coordinate(coordinate2D: from.coordinate, level: 0)
        let destination = Coordinate(coordinate2D: to.coordinate, level: 1)
        
        // for debugging
//        let origin = Coordinate(coordinate2D: .init(latitude: 48.844548658057306, longitude: 2.3732023740778025), level: 0)
//        let destination = Coordinate(coordinate2D: .init(latitude: 48.84442126724909, longitude: 2.373656619804761), level: 1)
        
        map.navigationManager
            .startNavigation(from: origin, to: destination, options: options)
            .subscribe(
                onSuccess: { [unowned self] itinerary in
                    debugPrint("Navigation started successfully")
                    stopNavigationButton.isEnabled = true
                    simulator.setItinerary(itinerary)
                },
                onFailure: { [unowned self] error in
                    debugPrint("Failed to start navigation with error - \(error)")
                    updateStartNavigationButtons()
                    ToastHelper.showToast(
                        message: "Failed to start navigation from - \(origin) to - \(destination) with error - \(error)",
                        onView: view,
                        hideDelay: 10
                    )
                }
            ).disposed(by: disposeBag)
    }
    
    @IBAction func removeUserCreatedAnnotations() {
        map.removeAnnotations(userCreatedAnnotations)
        removeUserCreatedAnnotationsButton.isEnabled = false
        
        startNavigationButton.isEnabled = false
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = false
    }
    
    private func updateStartNavigationButtons() {
        startNavigationButton.isEnabled = userCreatedAnnotations.count == 1
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = userCreatedAnnotations.count == 2
    }
}

extension NavigationViewController: BuildingManagerDelegate {
    
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

extension NavigationViewController: WemapMapViewDelegate {
    
    func map(_: MapView, didTouchPointOfInterest _: PointOfInterest) {
        debugPrint(#function)
    }
    
    func map(_: MapView, didTouchItinerary _: Itinerary) {
        debugPrint(#function)
    }
    
    func map(_: MapView, didTouchFeature feature: MGLFeature) {
        ToastHelper.showToast(
            message: "Touched feature - \(feature)",
            onView: view,
            hideDelay: 5
        )
    }
}

extension NavigationViewController: NavigationDelegate {
    
    func navigationManager(_: NavigationManager, didUpdateNavigationInfo info: NavigationInfo) {
        navigationInfo.isHidden = false
        navigationInfo.text = info.shortDescription
    }
}

// swiftlint:enable force_cast
