//
//  NavigationViewController.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import ARKit
import MapLibre
import UIKit
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKVPSARKit

final class NavigationViewController: MapViewController {

    typealias Delay = UIConstants.Delay
    typealias Inset = UIConstants.Inset

    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var removeUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!
    @IBOutlet var userTrackingModeButton: UIButton!
    @IBOutlet var localizeButton: UIButton!

    private weak var currentVPSToast: UIView?

    private var userCreatedAnnotations: [MLNAnnotation] {
        map.annotations?
            .filter { $0.title == "user-created" } ?? []
    }

    private var simulator: SimulatorLocationSource? {
        map.userLocationManager.locationSource as? SimulatorLocationSource
    }

    private var vpsLocationSource: VPSARKitLocationSource? {
        map.userLocationManager.locationSource as? VPSARKitLocationSource
    }

    private var navigationManager: MapNavigationManaging {
        map.navigationManager
    }

    private var observationTasks: [Task<Void, Never>] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        createLongPressGestureRecognizer()
        localizeButton.isHidden = locationSourceType != .vps
    }

    override func lateInit() {
        super.lateInit()

        let selectionUpdates = pointOfInterestManager.selectionUpdates
        let locationErrors = map.userLocationManager.errors
        observationTasks = [
            Task { [weak self] in
                for await update in selectionUpdates {
                    guard let self else {
                        return
                    }
                    let message = "POI(s) selected with id(s) - \(update.selected.map(\.id))"
                    ToastHelper.showToast(message: message, onView: view, hideDelay: Delay.short)
                }
            },
            Task {
                for await error in locationErrors {
                    print("LocationManager failed with error - \(error)")
                }
            }
        ]

        if let vpsLocationSource {
            let states = vpsLocationSource.states
            observationTasks.append(
                Task { [weak self] in
                    for await state in states {
                        guard let self else {
                            return
                        }
                        handleStateChange(state)
                    }
                }
            )
            handleStateChange(vpsLocationSource.state)
        }

        subscribeToNavigationEvents()
    }

    private func subscribeToNavigationEvents() {
        let navigationEvents = navigationManager.navigationEvents
        let navigationInfoUpdates = navigationManager.navigationInfoUpdates
        let navigationErrors = navigationManager.errors
        
        observationTasks.append(contentsOf: [
            Task { [weak self] in
                for await event in navigationEvents {
                    guard let self else {
                        return
                    }
                    handleNavigationEvent(event)
                }
            },
            Task { [weak self] in
                for await info in navigationInfoUpdates {
                    guard let self else {
                        return
                    }
                    handleNavigationInfo(info)
                }
            },
            Task { [weak self] in
                for await error in navigationErrors {
                    guard let self else {
                        return
                    }
                    let message = "Navigation failed with error - \(error)"
                    ToastHelper.showToast(message: message, onView: view, hideDelay: Delay.short)
                }
            }
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ToastHelper.showToast(
            message: "Create 1 or 2 annotations by long press on the map to be able to start navigation. " +
                "1 annotation to start from user location. 2 annotations to start from custom location",
            onView: view, hideDelay: Delay.short
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for task in observationTasks {
            task.cancel()
        }
        observationTasks.removeAll()
    }

    override func mapLoaded() {
        super.mapLoaded()
        map.userTrackingMode = .follow
    }

    // MARK: - Actions

    @IBAction func closeTouched() {
        dismiss(animated: true)
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

    @IBAction func localize() {
        showCamera(session: vpsLocationSource!.session)
    }

    @IBAction func userTrackingModeButtonTouched() {

        var nextModeRaw = map.userTrackingMode.rawValue + 1
        nextModeRaw = nextModeRaw < 3 ? nextModeRaw : 0
        map.userTrackingMode = MLNUserTrackingMode(rawValue: nextModeRaw)!

        updateUserTrackingModeButtonTitle()
    }

    // MARK: - Private

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
        updateUI()
    }

    private func getCurrentLevel(for coordinate: CLLocationCoordinate2D) -> String {
        guard let building = focusedBuilding else {
            print("Failed to retrieve focused building. Considering this annotation as outdoor")
            return String()
        }

        return building.boundingBox.contains(coordinate) ? String(building.activeLevel.id) : String()
    }

    private func updateUserTrackingModeButtonTitle() {
        let title: String = switch map.userTrackingMode {
        case .none: "none"
        case .follow: "follow"
        case .followWithHeading: "heading"
        default: fatalError()
        }

        userTrackingModeButton.setTitle(title, for: .normal)
    }

    private func startNavigation(origin: Coordinate?, destination: Coordinate) {
        disableStartButtons()

        Task {
            do {
                let navigation = try await navigationManager.startNavigation(origin: origin, destination: destination)
                simulator?.setItinerary(navigation.itinerary)
                stopNavigationButton.isEnabled = true
            } catch {
                let text = "Failed to start navigation from user position to - \(destination) with error - \(error)"
                ToastHelper.showToast(message: text, onView: view, hideDelay: Delay.long)
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

    private func showCamera(session: ARSession) {
        // swiftlint:disable:next force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "cameraVC") as! CameraViewController
        vc.session = session
        vc.vpsLocationSource = vpsLocationSource!
        vc.locationErrors = map.userLocationManager.errors
        present(vc, animated: true)
    }

    private func handleStateChange(_ state: VPSARKitLocationSource.State) {
        print("VPS state changed - \(state)")

        switch state {
        case .notPositioning:
            showVPSToast(message: "Scan is required. Please click on localize, scan your environment. "
                + "Camera will be closed automatically as soon as you're localized")
        case let .degradedPositioning(reason):
            showVPSToast(message: "Tracking is limited due to - \(reason)")
        default: // .accuratePositioning
            currentVPSToast?.removeFromSuperview()
        }
    }

    private func showVPSToast(message: String) {
        currentVPSToast?.removeFromSuperview()
        currentVPSToast = ToastHelper.showToast(message: message, onView: view, hideDelay: 20, bottomInset: -200)
    }
}

// MARK: - Navigation event handlers

private extension NavigationViewController {

    func handleNavigationEvent(_ event: NavigationEvent) {
        switch event {
        case .started: handleNavigationStarted()
        case .stopped: handleNavigationStopped()
        case .arrived: handleArrivalAtDestination()
        case let .recalculated(navigation): handleNavigationRecalculated(navigation)
        @unknown default:
            fatalError()
        }
    }

    func handleNavigationInfo(_ info: NavigationInfo) {
        navigationInfo.isHidden = false
        navigationInfo.text = info.description
    }

    func handleNavigationStarted() {
        navigationInfo.isHidden = false
        ToastHelper.showToast(message: "Navigation started", onView: view)
        stopNavigationButton.isEnabled = true
    }

    func handleNavigationStopped() {
        navigationInfo.isHidden = true
        ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: Delay.short)
        stopNavigationButton.isEnabled = false
        updateUI()
    }

    func handleArrivalAtDestination() {
        ToastHelper.showToast(message: "Navigation didArriveAtDestination", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }

    func handleNavigationRecalculated(_ navigation: Navigation) {
        ToastHelper.showToast(message: "Navigation recalculated - \(navigation)", onView: view, hideDelay: Delay.short)
    }
}

// MARK: - MLNMapViewDelegate

extension NavigationViewController: @MainActor MLNMapViewDelegate {

    func mapView(_: MLNMapView, didChange _: MLNUserTrackingMode, animated _: Bool) {
        updateUserTrackingModeButtonTitle()
    }
}
