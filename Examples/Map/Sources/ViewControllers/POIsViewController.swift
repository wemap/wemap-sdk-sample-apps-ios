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
    
    typealias Delay = UIConstants.Delay
    typealias Inset = UIConstants.Inset
    
    @IBOutlet var applyFilterButton: UIButton!
    @IBOutlet var removeFiltersButton: UIButton!
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromSimulatedUserPositionButton: UIButton!
    @IBOutlet var removeSimulatedUserPositionButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!
    @IBOutlet var toggleSelectionButton: UIButton!
    @IBOutlet var poisByDistanceButton: UIButton!
    @IBOutlet var poisByTimeButton: UIButton!
    
    private var simulator: SimulatorLocationSource? {
        map.userLocationManager.locationSource as? SimulatorLocationSource
    }
    
    private var navigationManager: NavigationManager { map.navigationManager }
    
    private var selectedPOI: PointOfInterest?
    private var simulatedUserPosition: MGLAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.mapDelegate = self
        navigationManager.delegate = self
        pointOfInterestManager.delegate = self
        
        map.userTrackingMode = .followWithHeading
        
        createLongPressGestureRecognizer()
        toggleSelectionButton.setTitle("Enable selection", for: .selected)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ToastHelper.showToast(
            message: "Select one POI on the map and after click on start navigation button. " +
                "If you use simulator - perform long tap at any place on the map and then select at least one POI to start navigation",
            onView: view, hideDelay: Delay.short
        )
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func startNavigation() {
        startNavigationToSelectedPOI()
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
    
    @IBAction func startNavigationFromSimulatedUserPosition() {
        let origin = getCoordinateFromSimulatedUserPosition()
        startNavigationToSelectedPOI(origin: origin)
    }
    
    @IBAction func removeSimulatedUserPosition() {
        map.removeAnnotation(simulatedUserPosition!)
        simulatedUserPosition = nil
        updateUI()
    }
    
    @IBAction func applyFilter() {
        if pointOfInterestManager.filterByTag("52970") {
            applyFilterButton.isEnabled = false
            removeFiltersButton.isEnabled = true
        }
    }
    
    @IBAction func removeFilters() {
        pointOfInterestManager.removeFilters()
        applyFilterButton.isEnabled = true
        removeFiltersButton.isEnabled = false
    }
    
    @IBAction func toggleSelection() {
        toggleSelectionButton.isSelected.toggle()
        pointOfInterestManager.isSelectionEnabled.toggle()
    }
    
    private func startNavigationToSelectedPOI(origin: Coordinate? = nil) {
        disableStartButtons()
        
        let destination = selectedPOI!.coordinate
        
        navigationManager
            .startNavigation(from: origin, to: destination, options: globalNavigationOptions)
            .subscribe(
                onSuccess: { [unowned self] itinerary in
                    simulator?.setItinerary(itinerary)
                    stopNavigationButton.isEnabled = true
                },
                onFailure: { [unowned self] error in
                    ToastHelper.showToast(message: "Failed to start navigation to - \(destination) with error - \(error)", onView: view, hideDelay: Delay.long)
                    updateUI()
                }
            ).disposed(by: disposeBag)
    }
    
    private func createLongPressGestureRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        map.addGestureRecognizer(longPress)
    }
    
    @objc private func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        
        if let simulatedUserPosition {
            map.removeAnnotation(simulatedUserPosition)
        }
        
        let coord = map.convert(gesture.location(in: map), toCoordinateFrom: map)
        let point = MGLPointAnnotation()
        point.coordinate = coord
        point.subtitle = "\(focusedBuilding?.activeLevel.id ?? 0.0)"
        map.addAnnotation(point)
        simulatedUserPosition = point
        updateUI()
    }
    
    private func updateUI() {
        startNavigationButton.isEnabled = selectedPOI != nil && !stopNavigationButton.isEnabled
        startNavigationFromSimulatedUserPositionButton.isEnabled = selectedPOI != nil && simulatedUserPosition != nil && !stopNavigationButton.isEnabled
        removeSimulatedUserPositionButton.isEnabled = simulatedUserPosition != nil
        poisByDistanceButton.isEnabled = simulatedUserPosition != nil
        poisByTimeButton.isEnabled = simulatedUserPosition != nil
    }
    
    private func disableStartButtons() {
        startNavigationButton.isEnabled = false
        startNavigationFromSimulatedUserPositionButton.isEnabled = false
    }
    
    private func getLevelFromAnnotation(_ annotation: MGLAnnotation) -> [Float] {
        guard let building = focusedBuilding else {
            debugPrint("Failed to rerieve focused building. Can't check if annotation is indoor or outdoor")
            return []
        }
        
        return building.boundingBox.contains(annotation.coordinate) ? [Float(annotation.subtitle!!)!] : []
    }
    
    private func unselectSelectedPOI() {
        if let selectedPOI {
            pointOfInterestManager.unselectPOI(selectedPOI)
        }
        selectedPOI = nil
    }
    
    private func getCoordinateFromSimulatedUserPosition() -> Coordinate {
        let from = simulatedUserPosition!
        return Coordinate(coordinate2D: from.coordinate, levels: getLevelFromAnnotation(from))
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! POIsListViewController // swiftlint:disable:this force_cast
        vc.mapView = map
        vc.userCoordinate = getCoordinateFromSimulatedUserPosition()
        
        if let button = sender as? UIButton, button == poisByDistanceButton {
            vc.sortingType = .distance
        } else {
            vc.sortingType = .time
        }
    }
}

extension POIsViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest) {
        unselectSelectedPOI()
        selectedPOI = poi
        updateUI()
    }
    
    func pointOfInterestManager(_: PointOfInterestManager, didUnselectPointOfInterest _: PointOfInterest) {
        selectedPOI = nil
        updateUI()
    }
}

extension POIsViewController: NavigationManagerDelegate {
    
    func navigationManager(_: NavigationManager, didUpdateNavigationInfo info: NavigationInfo) {
        navigationInfo.isHidden = false
        navigationInfo.text = info.description
    }
    
    func navigationManager(_: NavigationManager, didStartNavigation _: Itinerary) {
        navigationInfo.isHidden = false
        ToastHelper.showToast(message: "Navigation started", onView: view)
        stopNavigationButton.isEnabled = true
    }
    
    func navigationManager(_: NavigationManager, didStopNavigation _: Itinerary) {
        navigationInfo.isHidden = true
        ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: Delay.short)
        stopNavigationButton.isEnabled = false
    }
    
    func navigationManager(_: NavigationManager, didArriveAtDestination _: Itinerary) {
        ToastHelper.showToast(message: "Navigation manager didArriveAtDestination", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }
    
    func navigationManager(_: NavigationManager, didFailWithError error: NavigationError) {
        navigationInfo.isHidden = true
        ToastHelper.showToast(message: "Navigation failed with error - \(error)", onView: view, hideDelay: Delay.short)
    }
    
    func navigationManager(_: NavigationManager, didRecalculateItinerary itinerary: Itinerary) {
        ToastHelper.showToast(message: "Navigation itinerary recalculated - \(itinerary)", onView: view, hideDelay: Delay.short)
    }
}

extension POIsViewController: WemapMapViewDelegate {
    
    func map(_: MapView, didTouchFeature _: MGLFeature) {
        ToastHelper.showToast(message: "didTouchFeature", onView: view, hideDelay: Delay.short)
    }
    
    func map(_: MapView, didTouchAtPoint _: CGPoint) {
        unselectSelectedPOI()
    }
}
