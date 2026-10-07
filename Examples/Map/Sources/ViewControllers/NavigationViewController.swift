//
//  NavigationViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import MapLibre
import UIKit
import WemapCoreSDK
import WemapMapSDK

/**
 Navigating between points the user drops on the map: long-press to place one or two annotations, then
 navigate from the user's position or between the two.
 */
final class NavigationViewController: MapViewController {

    typealias Delay = UIConstants.Delay

    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var removeUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!
    @IBOutlet var wheelchairSwitch: UISwitch!

    private var userCreatedAnnotations: [MLNAnnotation] {
        map.annotations?
            .filter { $0.title == "user-created" } ?? []
    }

    private var simulator: SimulatorLocationSource? {
        map.userLocationManager.locationSource as? SimulatorLocationSource
    }

    private var navigationManager: MapNavigationManaging {
        map.navigationManager
    }

    private var observationTasks: [Task<Void, Never>] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Navigation"

        createLongPressGestureRecognizer()
        updateUI()
    }

    override func lateInit() {
        super.lateInit()

        let selectionUpdates = pointOfInterestManager.selectionUpdates
        observationTasks = [
            Task { [weak self] in
                for await update in selectionUpdates {
                    guard let self else {
                        return
                    }
                    let message = "POI(s) selected with id(s) - \(update.selected.map(\.id))"
                    ToastHelper.showToast(message: message, onView: view, hideDelay: Delay.short)
                }
            }
        ]
        observationTasks += observeNavigation(infoLabel: navigationInfo) { [weak self] isNavigating in
            self?.stopNavigationButton.isEnabled = isNavigating
            self?.updateUI()
        }
        printSearchRuleNames()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let message = """
            Create 1 or 2 annotations by long press on the map to be able to start navigation.
            1 annotation to start from user location. 2 annotations to start from custom location"
        """
        ToastHelper.showToast(message: message, onView: view, hideDelay: Delay.short)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for task in observationTasks {
            task.cancel()
        }
        observationTasks.removeAll()
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
            print("Failed to retrieve focused building. Considering this annotation as outdoor")
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

        let rules: ItinerarySearchRules = wheelchairSwitch.isOn ? .wheelchair : .init()

        Task {
            do {
                let navigation = try await navigationManager.startNavigation(
                    origin: origin, destination: destination, options: globalNavigationOptions,
                    searchRules: rules, itineraryOptions: globalItineraryOptions
                )
                simulator?.setItinerary(navigation.itinerary)
                stopNavigationButton.isEnabled = true
            } catch {
                stopNavigationButton.isEnabled = false
                updateUI()
                ToastHelper.showToast(
                    message: "Failed to start navigation from user position to - \(destination) with error - \(error)",
                    onView: view, hideDelay: Delay.long
                )
            }
        }
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

    private func getLevelFromAnnotation(_ annotation: MLNAnnotation) -> Levels {
        guard let subtitle = annotation.subtitle!, !subtitle.isEmpty, let level = Float(subtitle) else {
            return .outdoor
        }
        return .single(level)
    }
}
