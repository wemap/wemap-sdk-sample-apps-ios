//
//  POIsViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import MapLibre
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
    private var observationTasks: [Task<Void, Never>] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Points of interest"
        createLongPressGestureRecognizer()
    }

    override func lateInit() {
        super.lateInit()

        let touchedPOIs = pointOfInterestManager.touchedPOIs
        let locationManager = map.userLocationManager
        let coordinates = locationManager.coordinates
        observationTasks = [
            Task { [weak self] in
                for await poi in touchedPOIs {
                    guard let self else {
                        return
                    }
                    ToastHelper.showToast(message: "didTouchPointOfInterest - \(poi)", onView: view, hideDelay: Delay.short)
                }
            },
            Task { [weak self] in
                var iterator = coordinates.makeAsyncIterator()
                guard let firstCoordinate = await iterator.next(), let self else {
                    return
                }
                enableSortButtons()
                navigationInfoLabel.text = firstCoordinate.compactDescription
            }
        ]
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for task in observationTasks {
            task.cancel()
        }
        observationTasks.removeAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let text = "If you use simulator, long tap at any place on the map to simulate user location. " +
            "After you'll be able to sort POIs by time/distance"
        ToastHelper.showToast(message: text, onView: view, hideDelay: Delay.short)
    }

    @IBAction func userSelectionSwitchToggle() {
        pointOfInterestManager.isUserSelectionEnabled = userSelectionSwitch.isOn
    }
    
    @IBAction func toggleSelection() {
        var newModeRaw = pointOfInterestManager.selectionMode.rawValue + 1
        newModeRaw = newModeRaw < PointOfInterestSelectionMode.allCases.count ? newModeRaw : 0
        let newMode = PointOfInterestSelectionMode(rawValue: newModeRaw)!
        
        pointOfInterestManager.selectionMode = newMode
        toggleSelectionButton.setTitle("Selection: \(newMode.description)", for: .normal)
    }
    
    @IBAction func applyFilter() {
        if pointOfInterestManager.filterByTags(["53003", "53014"], matchMode: .and) {
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
            ToastHelper.showToast(message: "Hidden POI is nil", onView: view)
            return
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
        guard let randomPOI = pointOfInterestManager.getAllPOIs().randomElement() else {
            ToastHelper.showToast(message: "Random POI is nil", onView: view)
            return
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
        point.subtitle = getCurrentLevel(for: coord)
        map.addAnnotation(point)
        simulatedUserPosition = point
        enableSortButtons()
    }

    private func getCurrentLevel(for coordinate: CLLocationCoordinate2D) -> String {
        guard let building = focusedBuilding else {
            print("Failed to retrieve focused building. Considering this annotation as outdoor")
            return String()
        }

        return building.boundingBox.contains(coordinate) ? String(building.activeLevel.id) : String()
    }

    private func getLevelFromAnnotation(_ annotation: MLNAnnotation) -> Levels {
        guard let subtitle = annotation.subtitle!, !subtitle.isEmpty, let level = Float(subtitle) else {
            return .outdoor
        }
        return .single(level)
    }

    override func mapTouched(at _: CGPoint) {
        if pointOfInterestManager.selectionMode.isSingle {
            _ = pointOfInterestManager.unselectPOI()
        } else {
            _ = pointOfInterestManager.unselectAllPOIs()
        }
    }

    override func mapLoadingFailed(error: any Error) {
        let message = "Failed to load map with error - \(error)"
        ToastHelper.showToast(message: message, onView: view, bottomInset: UIConstants.Inset.top)
    }

    private func updateShowHidePOIButtons() {
        let hiddenPOIExists = hiddenPOI != nil
        showHiddenPOIButton.isEnabled = hiddenPOIExists
        hideRandomPOIButton.isEnabled = !hiddenPOIExists
    }
    
    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier _: String, sender _: Any?) -> Bool {
        guard !pointOfInterestManager.getAllPOIs().isEmpty else {
            ToastHelper.showToast(message: "This map has no POIs. So nothing to sort by distance or time", onView: view)
            return false
        }
        return true
    }

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
