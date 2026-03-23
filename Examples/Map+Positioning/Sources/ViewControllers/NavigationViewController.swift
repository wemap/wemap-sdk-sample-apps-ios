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

    private let vpsDelegateDispatcher = VPSDelegateDispatcher()
    private let locationManagerDelegateDispatcher = LocationManagerDelegateDispatcher()

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

    override func viewDidLoad() {
        super.viewDidLoad()
        createLongPressGestureRecognizer()
        localizeButton.isHidden = locationSourceType != .vps
    }

    override func lateInit() {
        super.lateInit()

        navigationManager.delegate = self
        pointOfInterestManager.delegate = self

        map.userLocationManager.delegate = locationManagerDelegateDispatcher
        vpsLocationSource?.vpsDelegate = vpsDelegateDispatcher

        locationManagerDelegateDispatcher.primary = self
        vpsDelegateDispatcher.primary = self

        if let state = vpsLocationSource?.state {
            handleStateChange(state)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        ToastHelper.showToast(
            message: "Create 1 or 2 annotations by long press on the map to be able to start navigation. " +
            "1 annotation to start from user location. 2 annotations to start from custom location",
            onView: view, hideDelay: Delay.short
        )
    }

    override func mapViewLoaded(_ mapView: MapView, style: MLNStyle, data: MapData) {
        super.mapViewLoaded(mapView, style: style, data: data)
        map.userTrackingMode = .follow
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
        point.subtitle = "\(focusedBuilding?.activeLevel.id ?? 0.0)"
        map.addAnnotation(point)
        updateUI()
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

        navigationManager
            .startNavigation(origin: origin, destination: destination)
            .sink(receiveCompletion: { [unowned self] in
                if case let .failure(error) = $0 {
                    let text = "Failed to start navigation from user position to - \(destination) with error - \(error)"
                    ToastHelper.showToast(message: text, onView: view, hideDelay: Delay.long)
                }
            }, receiveValue: { [unowned self] navigation in
                simulator?.setItinerary(navigation.itinerary)
                stopNavigationButton.isEnabled = true
            })
            .store(in: &cancellables)
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
        guard let building = focusedBuilding else {
            debugPrint("Failed to retrieve focused building. Can't check if annotation is indoor or outdoor")
            return []
        }

        return building.boundingBox.contains(annotation.coordinate) ? [Float(annotation.subtitle!!)!] : []
    }

    private func showCamera(session: ARSession) {
        // swiftlint:disable:next force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "cameraVC") as! CameraViewController
        vc.session = session
        vc.vpsLocationSource = vpsLocationSource!
        vc.vpsDelegateDispatcher = vpsDelegateDispatcher
        vc.locationManagerDelegateDispatcher = locationManagerDelegateDispatcher
        present(vc, animated: true)
    }

    private func handleStateChange(_ state: VPSARKitLocationSource.State) {
        debugPrint("VPS state changed - \(state)")

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

extension NavigationViewController: PointOfInterestManagerDelegate {

    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest) {
        ToastHelper.showToast(message: "POI clicked with id - \(poi.id)", onView: view, hideDelay: Delay.short)
    }
}

extension NavigationViewController: NavigationManagerDelegate {

    func navigationManager(_: NavigationManager, didUpdateNavigationInfo info: NavigationInfo) {
        navigationInfo.isHidden = false
        navigationInfo.text = info.description
    }

    func navigationManager(_: NavigationManager, didStartNavigation _: Navigation) {
        navigationInfo.isHidden = false
        ToastHelper.showToast(message: "Navigation started", onView: view)
        stopNavigationButton.isEnabled = true
    }

    func navigationManager(_: NavigationManager, didStopNavigation _: Navigation) {
        navigationInfo.isHidden = true
        ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: Delay.short)
        stopNavigationButton.isEnabled = false
        updateUI()
    }

    func navigationManager(_: NavigationManager, didArriveAtDestination _: Navigation) {
        ToastHelper.showToast(message: "Navigation didArriveAtDestination", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }

    func navigationManager(_: NavigationManager, didFailWithError error: Error) {
        ToastHelper.showToast(message: "Navigation failed with error - \(error)", onView: view, hideDelay: Delay.short)
    }

    func navigationManager(_: NavigationManager, didRecalculateNavigation navigation: Navigation) {
        ToastHelper.showToast(message: "Navigation recalculated - \(navigation)", onView: view, hideDelay: Delay.short)
    }
}

extension NavigationViewController: VPSARKitLocationSourceDelegate {

    func locationSource(_: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
        handleStateChange(state)
    }
}

extension NavigationViewController: UserLocationManagerDelegate {

    func locationManager(_: UserLocationManager, didFailWithError error: any Error) {
        debugPrint("LocationManager failed with error - \(error)")
    }
}
