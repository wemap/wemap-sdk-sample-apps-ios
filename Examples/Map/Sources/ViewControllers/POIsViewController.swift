//
//  POIsViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Mapbox
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class POIsViewController: MapViewController {
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromSimulatedUserPositionButton: UIButton!
    @IBOutlet var removeSimulatedUserPositionButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!

    private let disposeBag = DisposeBag()
    
    var selectedPOI: PointOfInterest?
    
    private var simulator: LocationSourceSimulator? {
        map.userLocationManager.locationSource as? LocationSourceSimulator
    }
    
    private var pointOfInterestManager: PointOfInterestManager {
        map.pointOfInterestManager
    }
    
    private var navigationManager: NavigationManager {
        map.navigationManager
    }
    
    private var userCreatedAnnotations: [MGLAnnotation] {
        map.annotations?
            .filter { $0.title == "user-created" } ?? []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationManager.delegate = self
        pointOfInterestManager.delegate = self
        
        map.userTrackingMode = .followWithHeading
        
        createLongPressGestureRecognizer()
        
        // to see coordinate returned by location source
        weak var previous: UIView?
        map.userLocationManager
            .coordinateUpdated
            .subscribe(onNext: { [unowned self] in
                previous?.removeFromSuperview()
                previous = ToastHelper.showToast(message: "Location: \($0)", onView: view, bottomInset: -200)
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ToastHelper.showToast(message: "Select one POI on the map and after click on start navigation button. " +
            "If you use simulator - perform long tap at any place on the map and then select at least one POI to start navigation",
            onView: view, hideDelay: 5)
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func startNavigation() {
        startNavigationButton.isEnabled = false
        
        let destination = Coordinate(coordinate2D: selectedPOI!.coordinate2D, level: selectedPOI!.levelID!)
        
        navigationManager
            .startNavigation(to: destination, options: Constants.globalNavigationOptions)
            .subscribe(
                onSuccess: { [unowned self] itinerary in
                    simulator?.setItinerary(itinerary)
                },
                onFailure: { [unowned self] error in
                    debugPrint("Failed to start navigation with error - \(error)")
                    updateUI()
                    ToastHelper.showToast(
                        message: "Failed to start navigation to - \(destination) with error - \(error)",
                        onView: view,
                        hideDelay: 10
                    )
                }
            ).disposed(by: disposeBag)
    }
    
    @IBAction func stopNavigation() {
        let result = navigationManager.stopNavigation()
        switch result {
        case .success:
            simulator?.reset()
            stopNavigationButton.isEnabled = false
        case let .failure(error):
            ToastHelper.showToast(
                message: "Failed to stop navigation with error - \(error)",
                onView: view,
                hideDelay: 10
            )
        }
    }
    
    @IBAction func startNavigationFromSimulatedUserPosition() {
        
        startNavigationFromSimulatedUserPositionButton.isEnabled = false
        
        let from = userCreatedAnnotations[0]
        
        let origin = Coordinate(coordinate2D: from.coordinate, levels: getLevelFromAnnotation(from))
        let destination = Coordinate(coordinate2D: selectedPOI!.coordinate2D, level: selectedPOI!.levelID!)
        
        navigationManager
            .startNavigation(from: origin, to: destination, options: Constants.globalNavigationOptions)
            .subscribe(
                onSuccess: { [unowned self] itinerary in
                    simulator?.setItinerary(itinerary)
                },
                onFailure: { [unowned self] error in
                    debugPrint("Failed to start navigation with error - \(error)")
                    updateUI()
                    ToastHelper.showToast(
                        message: "Failed to start navigation to - \(destination) with error - \(error)",
                        onView: view,
                        hideDelay: 10
                    )
                }
            ).disposed(by: disposeBag)
    }
    
    @IBAction func removeSimulatedUserPosition() {
        map.removeAnnotations(userCreatedAnnotations)
        removeSimulatedUserPositionButton.isEnabled = false
        startNavigationFromSimulatedUserPositionButton.isEnabled = false
    }
    
    private func getLevelFromAnnotation(_ annotation: MGLAnnotation) -> [Float] {
        guard let building = map.buildingManager.focusedBuilding else {
            debugPrint("Failed to rerieve focused building. Can't check if annotation is indoor or outdoor")
            return []
        }
                
        return building.boundingBox.contains(annotation.coordinate) ? [Float(annotation.subtitle!!)!] : []
    }
    
    private func createLongPressGestureRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        map.addGestureRecognizer(longPress)
    }
    
    @objc private func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        guard userCreatedAnnotations.isEmpty else {
            ToastHelper.showToast(message: "You already created an annotations. Remove old one to be able to add new", onView: view)
            return
        }
        let coord = map.convert(gesture.location(in: map), toCoordinateFrom: map)
        let point = MGLPointAnnotation()
        point.coordinate = coord
        point.title = "user-created"
        point.subtitle = "\(map.buildingManager.focusedBuilding?.activeLevel.id ?? 0.0)"
        map.addAnnotation(point)
        updateUI()
        removeSimulatedUserPositionButton.isEnabled = true
    }
    
    private func updateUI() {
        startNavigationButton.isEnabled = selectedPOI != nil
        startNavigationFromSimulatedUserPositionButton.isEnabled = selectedPOI != nil && !userCreatedAnnotations.isEmpty
    }
}

extension POIsViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest) {
        if let selectedPOI {
            pointOfInterestManager.unselectPOI(selectedPOI)
        }
        selectedPOI = poi
        updateUI()
    }
    
    func pointOfInterestManager(_: PointOfInterestManager, didUnselectPointOfInterest _: PointOfInterest) {
        selectedPOI = nil
        updateUI()
    }
}

extension POIsViewController: NavigationDelegate {
    
    func navigationManager(_: NavigationManager, didUpdateNavigationInfo info: NavigationInfo) {
        navigationInfo.isHidden = false
        navigationInfo.text = info.shortDescription
    }
    
    func navigationManager(_: NavigationManager, didStartNavigation _: Itinerary) {
        stopNavigationButton.isEnabled = true
        startNavigationButton.isEnabled = false
        ToastHelper.showToast(
            message: "Navigation started",
            onView: view
        )
    }
    
    func navigationManager(_: NavigationManager, didStopNavigation _: Itinerary) {
        stopNavigationButton.isEnabled = false
        updateUI()
        ToastHelper.showToast(
            message: "Navigation stopped",
            onView: view,
            hideDelay: 5
        )
    }
    
    func navigationManager(_: NavigationManager, didArriveAtDestination _: Itinerary) {
        ToastHelper.showToast(
            message: "Navigation manager didArriveAtDestination",
            onView: view,
            hideDelay: 5,
            bottomInset: -150
        )
    }
    
    func navigationManager(_: NavigationManager, didFailWithError error: NavigationError) {
        updateUI()
        ToastHelper.showToast(
            message: "Navigation failed with error - \(error)",
            onView: view,
            hideDelay: 5
        )
    }
    
    func navigationManager(_: NavigationManager, didRecalculateItinerary itinerary: Itinerary) {
        ToastHelper.showToast(
            message: "Navigation itinerary recalculated - \(itinerary)",
            onView: view,
            hideDelay: 5
        )
    }
}
