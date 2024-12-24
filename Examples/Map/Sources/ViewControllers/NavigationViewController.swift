//
//  NavigationViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import MapLibre
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class NavigationViewController: MapViewController {
    
    typealias Delay = UIConstants.Delay
    typealias Inset = UIConstants.Inset
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var removeUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!
    
    private var userCreatedAnnotations: [MLNAnnotation] {
        map.annotations?
            .filter { $0.title == "user-created" } ?? []
    }
    
    private var simulator: SimulatorLocationSource? {
        map.userLocationManager.locationSource as? SimulatorLocationSource
    }
    
    private var navigationManager: MapNavigationManaging { map.navigationManager }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createLongPressGestureRecognizer()

        updateUI()
    }
    
    override func lateInit() {
        super.lateInit()
        
        navigationManager.delegate = self
        pointOfInterestManager.delegate = self
        
        map.userTrackingMode = .follow
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ToastHelper.showToast(
            message: "Create 1 or 2 annotations by long press on the map to be able to start navigation. " +
                "1 annotation to start from user location. 2 annotations to start from custom location",
            onView: view, hideDelay: Delay.short
        )
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
        let point = MLNPointAnnotation()
        point.coordinate = coord
        point.title = "user-created"
        point.subtitle = getCurrentLevel(for: coord)
        map.addAnnotation(point)
        
        map.setCenter(coord, zoomLevel: 18, edgePadding: .init(top: 0, left: 0, bottom: 200, right: 0))
        
        updateUI()
    }
    
    private func getCurrentLevel(for coordinate: CLLocationCoordinate2D) -> String {
        guard let building = focusedBuilding else {
            debugPrint("Failed to retrieve focused building. Considering this annotation as outdoor")
            return String()
        }
        
        return building.boundingBox.contains(coordinate) ? String(building.activeLevel.id) : String()
    }
    
    @IBAction func startNavigationFromUserLocation() {
        let to = userCreatedAnnotations.first!
        let destination = Coordinate(coordinate2D: to.coordinate, level: Float(to.subtitle!!)!)
        
        startNavigation(origin: nil, destination: destination)
    }
    
    @IBAction func stopNavigation() {
        let result = navigationManager.stopNavigation()
        switch result {
        case .success:
            simulator?.reset()
            stopNavigationButton.isEnabled = false
            updateUI()
        case let .failure(error):
            ToastHelper.showToast(message: "Failed to stop navigation with error - \(error)", onView: view, hideDelay: Delay.long)
        }
    }
    
    @IBAction func startNavigationFromUserCreatedAnnotations() {
        
        let from = userCreatedAnnotations[0]
        let to = userCreatedAnnotations[1]
        
        let fromLevels = getLevelFromAnnotation(from)
        let toLevels = getLevelFromAnnotation(to)
        
        let origin = Coordinate(coordinate2D: from.coordinate, levels: fromLevels)
        let destination = Coordinate(coordinate2D: to.coordinate, levels: toLevels)
        
        startNavigation(origin: origin, destination: destination)
    }
    
    @IBAction func removeUserCreatedAnnotations() {
        map.removeAnnotations(userCreatedAnnotations)
        updateUI()
    }
    
    private func startNavigation(origin: Coordinate?, destination: Coordinate) {
        disableStartButtons()
        
        navigationManager
            .startNavigation(origin: origin, destination: destination, options: globalNavigationOptions // ,
//                             searchOptions: .init(avoidStairs: true), itineraryOptions: globalItineraryOptions
            )
            .subscribe(
                onSuccess: { [unowned self] navigation in
                    simulator?.setItinerary(navigation.itinerary)
                    stopNavigationButton.isEnabled = true
                },
                onFailure: { [unowned self] error in
                    stopNavigationButton.isEnabled = false
                    updateUI()
                    ToastHelper.showToast(
                        message: "Failed to start navigation from user position to - \(destination) with error - \(error)",
                        onView: view, hideDelay: Delay.long
                    )
                }
            ).disposed(by: disposeBag)
    }
    
    private func updateUI() {
        startNavigationButton.isEnabled = userCreatedAnnotations.count == 1 && !stopNavigationButton.isEnabled
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = userCreatedAnnotations.count == 2 && !stopNavigationButton.isEnabled
        removeUserCreatedAnnotationsButton.isEnabled = !userCreatedAnnotations.isEmpty
    }
    
    private func disableStartButtons() {
        startNavigationButton.isEnabled = false
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = false
    }
    
    private func getLevelFromAnnotation(_ annotation: MLNAnnotation) -> [Float] {
        guard let subtitle = annotation.subtitle! else {
            return []
        }
        return subtitle.isEmpty ? [] : [Float(subtitle)!]
    }
}

extension NavigationViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest) {
        ToastHelper.showToast(message: "POI clicked with id - \(poi.id)", onView: view, hideDelay: Delay.short) {
            _ = self.pointOfInterestManager.unselectPOI(poi)
        }
    }
}

extension NavigationViewController: NavigationManagerDelegate {
    
    func navigationManager(_: NavigationManager, didUpdateNavigationInfo info: NavigationInfo) {
        navigationInfo.isHidden = false
        let nextStep = info.nextStep?.getNavigationInstructions().instructions ?? "no"
        navigationInfo.text = info.shortDescription + "\nNext - \(nextStep)"
    }
    
    func navigationManager(_: NavigationManager, didStartNavigation navigation: Navigation) {
        navigationInfo.isHidden = false
        ToastHelper.showToast(message: "Navigation started", onView: view)
        stopNavigationButton.isEnabled = true
        
        for step in navigation.itinerary.legs.flatMap(\.steps) {
            let instructions = step.getNavigationInstructions()
            debugPrint(instructions)
        }
    }
    
    func navigationManager(_: NavigationManager, didStopNavigation _: Navigation) {
        navigationInfo.isHidden = true
        ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: Delay.short)
        stopNavigationButton.isEnabled = false
        updateUI()
    }
    
    func navigationManager(_: NavigationManager, didArriveAtDestination _: Navigation) {
        ToastHelper.showToast(message: "Navigation manager didArriveAtDestination", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }
    
    func navigationManager(_: NavigationManager, didFailWithError error: Error) {
        ToastHelper.showToast(message: "Navigation failed with error - \(error)", onView: view, hideDelay: Delay.short)
    }
    
    func navigationManager(_: NavigationManager, didRecalculateNavigation navigation: Navigation) {
        ToastHelper.showToast(message: "Navigation recalculated - \(navigation)", onView: view, hideDelay: Delay.short)
    }
}
