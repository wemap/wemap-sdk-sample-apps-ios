//
//  NavigationViewController.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import ARKit
import MapLibre
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKVPSARKit

@available(iOS 13.0, *)
final class NavigationViewController: MapViewController {
    
    typealias Delay = UIConstants.Delay
    typealias Inset = UIConstants.Inset
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var removeUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!
    @IBOutlet var userTrackingModeButton: UIButton!
    
    private weak var currentVPSToast: UIView?
    
    private weak var cameraVC: CameraViewController?
    
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
    
    private var navigationManager: MapNavigationManaging { map.navigationManager }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createLongPressGestureRecognizer()
    }
    
    override func lateInit() {
        super.lateInit()
        
        navigationManager.delegate = self
        pointOfInterestManager.delegate = self
        vpsLocationSource?.vpsDelegate = self
        vpsLocationSource?.observer = self
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
    
    @IBAction func rescan() {
        showCamera(session: vpsLocationSource!.session)
    }
    
    @IBAction func userTrackingModeButtonTouched() {
        
        var nextModeRaw = map.userTrackingMode.rawValue + 1
        nextModeRaw = nextModeRaw < 3 ? nextModeRaw : 0
        
        map.userTrackingMode = MLNUserTrackingMode(rawValue: nextModeRaw)!
        
        let title: String
        switch map.userTrackingMode {
        case .none:
            title = "none"
        case .follow:
            title = "follow"
        case .followWithHeading:
            title = "heading"
        default:
            fatalError()
        }
        userTrackingModeButton.setTitle(title, for: .normal)
    }
    
    private func startNavigation(origin: Coordinate?, destination: Coordinate) {
        disableStartButtons()
        
        navigationManager
            .startNavigation(origin: origin, destination: destination)
            .subscribe(
                onSuccess: { [unowned self] navigation in
                    simulator?.setItinerary(navigation.itinerary)
                    stopNavigationButton.isEnabled = true
                },
                onFailure: { [unowned self] error in
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
        guard let building = focusedBuilding else {
            debugPrint("Failed to retrieve focused building. Can't check if annotation is indoor or outdoor")
            return []
        }
        
        return building.boundingBox.contains(annotation.coordinate) ? [Float(annotation.subtitle!!)!] : []
    }
    
    private func showCamera(session: ARSession, assignCamera: Bool = false) {
        // swiftlint:disable:next force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "cameraVC") as! CameraViewController
        vc.session = session
        vc.vpsLocationSource = vpsLocationSource!
        if assignCamera {
            cameraVC = vc
        }
        
        present(vc, animated: true)
    }
}

@available(iOS 13.0, *)
extension NavigationViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest) {
        ToastHelper.showToast(message: "POI clicked with id - \(poi.id)", onView: view, hideDelay: Delay.short) {
            _ = self.pointOfInterestManager.unselectPOI(poi)
        }
    }
}

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
extension NavigationViewController: VPSARKitLocationSourceDelegate {
    
    func locationSource(_: VPSARKitLocationSource, didFailWithError error: VPSARKitLocationSourceError) {
        debugPrint("VPS failed with error: \(error)")
    }
    
    func locationSource(_: VPSARKitLocationSource, didChangeScanStatus status: VPSARKitLocationSource.ScanStatus) {
        debugPrint("VPS scan status changed: \(status)")
    }
    
    func locationSource(_ locationSource: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
        
        debugPrint("state - \(state)")

        switch state {
        case .notPositioning where cameraVC == nil:
            showCamera(session: locationSource.session, assignCamera: true)
        case let .degradedPositioning(reason):
            showVPSToast(message: "Tracking is limited due to - \(reason)")
        default: // .accuratePositioning
            currentVPSToast?.removeFromSuperview()
        }
    }
    
    private func showVPSToast(message: String) {
        currentVPSToast?.removeFromSuperview()
        currentVPSToast = ToastHelper.showToast(message: message, onView: view, hideDelay: .infinity)
    }
}

@available(iOS 13.0, *)
extension NavigationViewController: VPSARKitLocationSourceObserver {
    
    func locationSource(_: VPSARKitLocationSource, didChangeMovementState state: Int) {
        let stateString = switch state {
        case 0: "unknown"
        case 1: "static"
        case 2: "dynamic"
        default: "not expected number \(state)"
        }
        debugPrint("Movement state changed to - \(stateString)")
    }
    
    func locationSource(_: VPSARKitLocationSource, didChangeConveyingState state: Int) {
        let stateString = switch state {
        case 0: "notConveying"
        case 1: "conveying"
        default: "not expected number \(state)"
        }
        debugPrint("Conveing state changed to - \(stateString)")
    }
}
