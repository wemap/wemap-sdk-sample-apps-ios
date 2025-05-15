//
//  POIsViewController.swift
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

final class POIsViewController: MapViewController {
    
    typealias Delay = UIConstants.Delay
    
    @IBOutlet var applyFilterButton: UIButton!
    @IBOutlet var removeFiltersButton: UIButton!
    @IBOutlet var showHiddenPOIButton: UIButton!
    @IBOutlet var hideRandomPOIButton: UIButton!
    @IBOutlet var showAllPOIsButton: UIButton!
    @IBOutlet var hideAllPOIsButton: UIButton!
    @IBOutlet var navigationInfoLabel: UILabel!
    @IBOutlet var toggleSelectionButton: UIButton!
    @IBOutlet var poisByDistanceButton: UIButton!
    @IBOutlet var poisByTimeButton: UIButton!
    @IBOutlet var userSelectionSwitch: UISwitch!
    
    private var hiddenPOI: PointOfInterest?
    private var simulatedUserPosition: MLNAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createLongPressGestureRecognizer()
    }
    
    override func lateInit() {
        super.lateInit()
        
        pointOfInterestManager.delegate = self
        
        map.userTrackingMode = .followWithHeading
        
        userSelectionSwitch.rx.isOn
            .subscribe(onNext: { [unowned self] isOn in
                pointOfInterestManager.isUserSelectionEnabled = isOn
            })
            .disposed(by: disposeBag)
        
        map.userLocationManager
            .rx.coordinate
            .take(1)
            .subscribe(onNext: { [unowned self] in
                enableSortButtons()
                navigationInfoLabel.text = $0.shortDescription
            })
            .disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let text = "If you use simulator, long tap at any place on the map to simulate user location. After you'll be able to sort POIs by time/distance"
        ToastHelper.showToast(message: text, onView: view, hideDelay: Delay.short)
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func toggleSelection() {
        var newModeRaw = pointOfInterestManager.selectionMode.rawValue + 1
        newModeRaw = newModeRaw < PointOfInterestManager.SelectionMode.allCases.count ? newModeRaw : 0
        let newMode = PointOfInterestManager.SelectionMode(rawValue: newModeRaw)!
        
        pointOfInterestManager.selectionMode = newMode
        toggleSelectionButton.setTitle("Selection: \(newMode.description)", for: .normal)
    }
    
    @IBAction func applyFilter() {
        if pointOfInterestManager.filterByTag("52970") {
            applyFilterButton.isEnabled = false
            removeFiltersButton.isEnabled = true
        }
    }
    
    @IBAction func removeFilters() {
        _ = pointOfInterestManager.removeFilters()
        applyFilterButton.isEnabled = true
        removeFiltersButton.isEnabled = false
    }
    
    @IBAction func showHiddenPOI() {
        guard let hiddenPOI else {
            fatalError("Hidden POI is nil")
        }
        
        ToastHelper.showToast(message: "Showing POI - \(hiddenPOI.name)", onView: view)
        pointOfInterestManager.centerToPOI(hiddenPOI)
        if pointOfInterestManager.showPOI(hiddenPOI) {
            self.hiddenPOI = nil
            updateShowHidePOIButtons()
        } else {
            ToastHelper.showToast(message: "Failed to show POI - \(hiddenPOI.name)", onView: view)
        }
    }
    
    @IBAction func hideRandomPOI() {
        guard let randomPOI = pointOfInterestManager.getPOIs().randomElement() else {
            fatalError("Random POI is nil")
        }
        
        ToastHelper.showToast(message: "Hiding POI - \(randomPOI.name)", onView: view)
        pointOfInterestManager.centerToPOI(randomPOI)
        if pointOfInterestManager.hidePOI(randomPOI) {
            hiddenPOI = randomPOI
            updateShowHidePOIButtons()
        } else {
            ToastHelper.showToast(message: "Failed to hide POI - \(randomPOI.name)", onView: view)
        }
    }
    
    @IBAction func showAllPOIs() {
        let shown = pointOfInterestManager.showAllPOIs()
        hideAllPOIsButton.isEnabled = shown
        showAllPOIsButton.isEnabled = !shown
    }
    
    @IBAction func hideAllPOIs() {
        let hidden = pointOfInterestManager.hideAllPOIs()
        hideAllPOIsButton.isEnabled = !hidden
        showAllPOIsButton.isEnabled = hidden
        if hidden {
            hiddenPOI = nil
            updateShowHidePOIButtons()
        }
    }
    
    // MARK: - Private
    
    private func enableSortButtons() {
        poisByTimeButton.isEnabled = true
        poisByDistanceButton.isEnabled = true
    }
    
    private func getLastCoordinate() -> Coordinate {
        map.userLocationManager.lastCoordinate ?? getSimulatedCoordinate()
    }
    
    private func getSimulatedCoordinate() -> Coordinate {
        let from = simulatedUserPosition!
        return Coordinate(coordinate2D: from.coordinate, levels: getLevelFromAnnotation(from))
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
        let point = MLNPointAnnotation()
        point.coordinate = coord
        point.subtitle = "\(focusedBuilding?.activeLevel.id ?? 0.0)"
        map.addAnnotation(point)
        simulatedUserPosition = point
        enableSortButtons()
    }
    
    private func getLevelFromAnnotation(_ annotation: MLNAnnotation) -> [Float] {
        guard let building = focusedBuilding else {
            debugPrint("Failed to rerieve focused building. Can't check if annotation is indoor or outdoor")
            return []
        }
        
        return building.boundingBox.contains(annotation.coordinate) ? [Float(annotation.subtitle!!)!] : []
    }
    
    override func mapView(_: MapView, didTouchAtPoint _: CGPoint) {
        if pointOfInterestManager.selectionMode.isSingle {
            _ = pointOfInterestManager.unselectPOI()
        } else {
            _ = pointOfInterestManager.unselectAllPOIs()
        }
    }
    
    private func updateShowHidePOIButtons() {
        let hiddenPOIExists = hiddenPOI != nil
        showHiddenPOIButton.isEnabled = hiddenPOIExists
        hideRandomPOIButton.isEnabled = !hiddenPOIExists
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! POIsListViewController // swiftlint:disable:this force_cast
        vc.poiManager = pointOfInterestManager
        vc.userCoordinate = getLastCoordinate()
        
        if let button = sender as? UIButton, button == poisByDistanceButton {
            vc.sortingType = .distance
        } else {
            vc.sortingType = .time
        }
    }
}

// MARK: - PointOfInterestManagerDelegate

extension POIsViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didTouchPointOfInterest poi: PointOfInterest) {
        ToastHelper.showToast(message: "didTouchPointOfInterest - \(poi)", onView: view, hideDelay: Delay.short)
    }
}
