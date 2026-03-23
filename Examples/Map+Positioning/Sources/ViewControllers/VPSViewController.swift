//
//  VPSViewController.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 20/06/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//
// swiftlint:disable file_length

import ARKit
import Combine
import MapLibre
import RealityKit
import UIKit
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKVPSARKit

// swiftlint:disable:next type_body_length
final class VPSViewController:
UIViewController, PointOfInterestManagerDelegate, UserLocationManagerDelegate, NavigationManagerDelegate, VPSARKitLocationSourceDelegate, MapViewDelegate {
    
    typealias Delay = UIConstants.Delay
    typealias Inset = UIConstants.Inset
    
    var mapData: MapData!
    
    @IBOutlet var localizeButton: UIButton!
    @IBOutlet var cameraButton: UIButton!
    @IBOutlet var degradedStateIcon: UIImageView!
    @IBOutlet var cameraOverlay: UIView!
    @IBOutlet var mapView: MapView!
    
    @IBOutlet var containerHeight: NSLayoutConstraint!
    
    @IBOutlet var poiView: UIView!
    @IBOutlet var poiInfo: UILabel!
    
    @IBOutlet var itineraryView: UIView!
    @IBOutlet var itineraryInfo: UILabel!
    
    @IBOutlet var navigationView: UIView!
    @IBOutlet var navigationInfo: UILabel!
    
    private var pointOfInterestManager: MapPointOfInterestManaging {
        mapView.pointOfInterestManager
    }

    private var navigationManager: MapNavigationManaging {
        mapView.navigationManager
    }

    private var itineraryManager: ItineraryManager {
        mapView.itineraryManager
    }

    private var locationManager: UserLocationManager {
        mapView.userLocationManager
    }
    
    private var currentItinerary: Itinerary? {
        itineraryManager.itineraries.first
    }
    
    private let levelSwitch = LevelSwitch()

    private var arView: ARView?
    private var scanningTimer: AnyCancellable?
    private var cancellables: Set<AnyCancellable> = []

    private weak var errorCameraToast: UILabel?
    private weak var vpsErrorCameraToast: UILabel?

    private var vpsLocationSource: VPSARKitLocationSource!
    private var rescanSuggested = false

    private let impreciseMessage = "Your location seems imprecise, you can scan again to refine your position if necessary"

    private lazy var haptic: UINotificationFeedbackGenerator? = AppConstants.enableHapticFeedback ? UINotificationFeedbackGenerator() : nil

    private weak var backgroundScanHint: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.mapDelegate = self
        mapView.mapData = mapData
        
        mapView.attributionButtonPosition = .bottomLeft
        
        cameraButton.layer.cornerRadius = 12
        localizeButton.layer.cornerRadius = 12
        
        mapView.addSubview(levelSwitch)
        NSLayoutConstraint.activate([
            levelSwitch.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
            levelSwitch.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8)
        ])
        
        updateLocateMeButtonIcon()
    }
    
    func mapViewLoaded(_ mapView: MapView, style _: MLNStyle, data _: MapData) {

        localizeButton.isEnabled = true
        mapView.mapLibreDelegate = self
        
        levelSwitch.bind(buildingManager: mapView.buildingManager)
        
        locationManager.delegate = self
        navigationManager.delegate = self
        pointOfInterestManager.delegate = self
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    // MARK: - Location
    
    @IBAction func locateMeButtonTouched() {
        guard locationManager.locationSource is VPSARKitLocationSource else {
            locateUser()
            return
        }
        
        switch vpsLocationSource.state {
        case .accuratePositioning:
            toggleNextUserTrackingMode()
        case .degradedPositioning:
            if rescanSuggested {
                toggleNextUserTrackingMode()
            } else {
                rescanSuggested = true
                
                let message = "\(impreciseMessage).\n\nThis alert will be shown only once. If you decide to scan later - click on camera button. " +
                    "We recommend you to scan again when you see warning icon on camera button"
                
                AlertFactory
                    .presentSimpleAlert(
                        message: message, errorMessage: "You decided to scan later",
                        positiveText: "Scan now", negativeText: "Scan later", on: self
                    )
                    .sink(receiveCompletion: { [unowned self] in
                        if case .failure = $0 {
                            toggleNextUserTrackingMode()
                            ToastHelper.showToast(message: "When you'll be ready to scan again - click on camera button", onView: view)
                        }
                    }, receiveValue: { [unowned self] in
                        startScan()
                        enableFollowIfNotAlreadyEnabled()
                    })
                    .store(in: &cancellables)
            }
        default: locateUser()
        }
    }
    
    @IBAction func cameraButtonTouched() {
        let message: String? = switch vpsLocationSource.state {
        case .accuratePositioning: "Do you think your position is inaccurate? Scan again"
        case .degradedPositioning: impreciseMessage
        default: nil // should never happen by design
        }
        locateUser(message: message)
    }
    
    private func toggleNextUserTrackingMode() {
        
        var nextModeRaw = mapView.userTrackingMode.rawValue + 1
        nextModeRaw = nextModeRaw < 3 ? nextModeRaw : 0
        
        mapView.setUserTrackingMode(.init(rawValue: nextModeRaw)!, animated: true, completionHandler: nil)
    }
    
    private func enableFollowIfNotAlreadyEnabled() {
        if !mapView.userTrackingMode.isFollowing {
            mapView.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        }
    }
    
    private func locateUser(message: String? = nil) {
        let message = message ?? "In order to be localized we will use your camera"
        checkLocationSource(message: message)
            .sink(receiveCompletion: { [unowned self] in
                if case let .failure(error) = $0 {
                    ToastHelper.showToast(message: (error as NSError).domain, onView: view, hideDelay: Delay.short)
                }
            }, receiveValue: { [unowned self] in
                startScan()
                enableFollowIfNotAlreadyEnabled()
            })
            .store(in: &cancellables)
    }
    
    private func checkLocationSource(message: String) -> AnyPublisher<Void, Error> {
        checkPermissions()
            .flatMap { [unowned self] in
                askForScan(message: message)
            }.flatMap { [unowned self] in
                createAndStartLocationSource()
            }
            .eraseToAnyPublisher()
    }
    
    private func createAndStartLocationSource() -> AnyPublisher<Void, Error> {
        if locationManager.locationSource is VPSARKitLocationSource {
            vpsLocationSource.start()
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        vpsLocationSource = VPSARKitLocationSource(mapData: mapData)
        guard vpsLocationSource != nil else {
            return Fail(error: NSError(domain: "Failed to create VPS location source", code: 0) as Error)
                .eraseToAnyPublisher()
        }
        vpsLocationSource.vpsDelegate = self
        locationManager.locationSource = vpsLocationSource
        vpsLocationSource.start()
        mapView.showsUserHeadingIndicator = true
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    private func startScan() {
        vpsLocationSource.startScan()
    }
    
    private func showCameraView(session: ARSession) {
        let arView = ARView(frame: view.frame)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cameraOverlay.insertSubview(arView, at: 0)
        arView.session = session
        self.arView = arView
        cameraOverlay.isHidden = false
    }
    
    @IBAction func closeCameraTouched() {
        vpsLocationSource.stopScan()
        scanningTimer?.cancel()
        cameraOverlay.isHidden = true
        arView?.session = ARSession() // workaround to avoid ARView automatically stop ARSession
        arView?.removeFromSuperview()
        arView = nil
    }
    
    private func updateLocateMeButtonIcon() {
        let iconName: String = switch mapView.userTrackingMode {
        case .none: "location"
        case .follow: "location.fill"
        case .followWithHeading: "location.north.line.fill"
        default: fatalError()
        }
        
        localizeButton.setImage(.init(systemName: iconName), for: .normal)
    }
    
    private func askForScan(message: String) -> AnyPublisher<Void, Error> {
        AlertFactory
            .presentSimpleAlert(message: message, errorMessage: "User refused to open camera", positiveText: "Open camera", on: self)
    }
    
    private func positioningLost(reason: VPSARKitLocationSource.State.NotPositioningReason) {
        mapView.setUserTrackingMode(.none, animated: true, completionHandler: nil)
        haptic?.notificationOccurred(.error)
        if locationManager.lastCoordinate != nil {
            locateUser(message: "We lost your position. In order to relocalize you we will use your camera. \(reason)")
        }
    }
    
    func locationManager(_: UserLocationManager, didFailWithError error: any Error) {
        if cameraOverlay.isHidden {
            return debugPrint("LocationManager failed with error - \(error)")
        }
        if let vpsError = error as? VPSARKitLocationSourceError, case .slowConnectionDetected = vpsError {
            let message = "This is taking longer than expected. It looks like your internet connection is slow or unstable"
            vpsErrorCameraToast?.removeFromSuperview()
            vpsErrorCameraToast = ToastHelper.showToast(message: message, onView: cameraOverlay, hideDelay: 5, bottomInset: Inset.top)
            return
        }
        errorCameraToast?.removeFromSuperview()
        errorCameraToast = ToastHelper.showToast(message: "\(error)", onView: cameraOverlay, hideDelay: 1)
    }

    func locationSource(_: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
        debugPrint("VPS state changed - \(state)")
        showBackgroundScanHintIfNeeded()

        cameraButton.isHidden = state.isLost
        degradedStateIcon.isHidden = !state.isDegraded

        if state.isLost {
            let reason = if case let .notPositioning(reason) = state {
                reason
            } else {
                VPSARKitLocationSource.State.NotPositioningReason.none
            }
            positioningLost(reason: reason)
        }
    }
    
    func locationSource(_: VPSARKitLocationSource, didChangeScanStatus status: VPSARKitLocationSource.ScanStatus) {
        debugPrint("Scan status changed - \(status)")
        switch status {
        case .started:
            showCameraView(session: vpsLocationSource.session)
            createScanningTimer()
        case .stopped:
            closeCameraTouched()
        }
    }

    func locationSource(_: VPSARKitLocationSource, didChangeBackgroundScanStatus status: VPSARKitLocationSource.ScanStatus) {
        debugPrint("Background scan status changed - \(status)")
        showBackgroundScanHintIfNeeded()
    }

    func locationSource(_: VPSARKitLocationSource, didLocalizeUserAtCoordinate _: Coordinate, attitude _: Attitude, backgroundScan: Bool) {
        guard !backgroundScan || vpsLocationSource.state.isDegraded else {
            return
        }
        haptic?.notificationOccurred(.success)
    }

    func locationSource(_: VPSARKitLocationSource, cameraDidChangeTrackingState camera: ARCamera) {
        debugPrint("Tracking state - \(camera.trackingState)")
    }

    private func showBackgroundScanHintIfNeeded() {
        guard vpsLocationSource.backgroundScanStatus.isStarted, vpsLocationSource.state.isDegraded else {
            backgroundScanHint?.removeFromSuperview()
            return
        }
        guard backgroundScanHint == nil else {
            return
        }
        backgroundScanHint = ToastHelper.showToast(
            message: "Please hold your phone vertically in front of you to let system recognize your surroundings",
            onView: view, hideDelay: .greatestFiniteMagnitude
        )
    }

    private func createScanningTimer() {
        scanningTimer = Timer
            .publish(every: 20, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.askToContinue()
            }
    }
    
    private func askToContinue() {
        scanningTimer = AlertFactory
            .presentSimpleAlert(
                message: "We cannot localize you. Do you want to continue to try?", errorMessage: "You decided to get back to the map",
                positiveText: "Continue", negativeText: "Back to map", on: self
            )
            .sink(receiveCompletion: { [unowned self] in
                if case .failure = $0 {
                    closeCameraTouched()
                    ToastHelper.showToast(message: "Failed to localize you in reasonable time. Try again later", onView: view, hideDelay: Delay.long)
                }
            }, receiveValue: { [unowned self] in
                createScanningTimer()
            })
    }

    // MARK: - POIs
    
    private func renderPOI(_ poi: PointOfInterest) {
        hideAllStatesUI()
        containerHeight.isActive = false
        poiView.isHidden = false
        poiInfo.text = poi.name
    }
    
    private func dismissPOI() {
        poiView.isHidden = true
        poiInfo.text = nil
        hideAllStatesUI()
    }
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest) {
        renderPOI(poi)
    }
    
    func pointOfInterestManager(_: PointOfInterestManager, didUnselectPointOfInterest _: PointOfInterest) {
        dismissPOI()
    }
    
    // MARK: - Itineraries
    
    @IBAction func computeItinerariesToPOI() {
        
        guard let selectedPOI = pointOfInterestManager.getSelectedPOI() else {
            return Logger.e("Can't compute itineraries, there is no selected POI")
        }
        
        if let origin = locationManager.lastCoordinate {
            calculateAndDrawItinerary(from: origin, to: selectedPOI.coordinate)
            return
        }
        
        checkLocationSource(message: "We need to know your location to compute the best route. We will use your camera to localize you")
            .handleEvents(receiveOutput: { [unowned self] in
                startScan()
            })
            .flatMap { [unowned self] in
                locationManager
                    .coordinatePublisher
                    .prefix(1)
                    .setFailureType(to: Error.self)
                    .timeout(.seconds(20), scheduler: DispatchQueue.main, customError: { WemapError.timeout })
            }
            .sink(receiveCompletion: { [unowned self] in
                if case let .failure(error) = $0 {
                    let message = if error is WemapError {
                        "It took too long to localize you. Please try again"
                    } else {
                        (error as NSError).domain
                    }
                    ToastHelper.showToast(message: message, onView: view, hideDelay: Delay.short)
                }
            }, receiveValue: { [unowned self] userLocation in
                calculateAndDrawItinerary(from: userLocation, to: selectedPOI.coordinate)
            })
            .store(in: &cancellables)
    }
    
    private func calculateAndDrawItinerary(from: Coordinate, to: Coordinate) {
        let searchRules: ItinerarySearchRules = AppConstants.useWheelchair ? .wheelchair : .init()
        itineraryManager
            .getItineraries(origin: from, destination: to, searchRules: searchRules)
            .sink(receiveCompletion: { [unowned self] in
                if case let .failure(error) = $0 {
                    ToastHelper.showToast(message: "Failed to compute itineraries with error - \(error)", onView: view)
                }
            }, receiveValue: { [unowned self] itineraries in
                renderItinerary(itineraries.first!)
            })
            .store(in: &cancellables)
    }
    
    private func renderItinerary(_ itinerary: Itinerary) {
        
        guard itineraryManager.addItinerary(itinerary).inserted else {
            ToastHelper.showToast(message: "Failed to add itinerary", onView: view)
            return
        }
        
        pointOfInterestManager.isUserSelectionEnabled = false
        hideAllStatesUI()
        itineraryView.isHidden = false
        containerHeight.isActive = false
        
        let currentPoi = pointOfInterestManager.getSelectedPOI()!
        itineraryInfo.text = "Itinerary from user position to \(currentPoi.name)\n" +
            "Distance: \(Int(itinerary.distance))m\n" +
            "Duration: \(Int(itinerary.duration))s"
    }
    
    @IBAction func closeItineraryTouched() {
        guard itineraryManager.removeItinerary(currentItinerary!) != nil else {
            ToastHelper.showToast(message: "Failed to remove itinerary", onView: view)
            return
        }
        
        pointOfInterestManager.isUserSelectionEnabled = true
        if let selectedPoI = pointOfInterestManager.getSelectedPOI() {
            renderPOI(selectedPoI)
        } else {
            hideAllStatesUI()
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func startNavigationTouched() {
        navigationManager
            .startNavigation(currentItinerary!, options: globalNavigationOptions)
            .sink(receiveCompletion: { [unowned self] in
                if case let .failure(error) = $0 {
                    ToastHelper.showToast(message: "Failed to start navigation with error - \(error)", onView: view)
                }
            }, receiveValue: { [unowned self] _ in
                renderNavigation()
            })
            .store(in: &cancellables)
    }
    
    private func renderNavigation() {
        UIApplication.shared.isIdleTimerDisabled = true
        hideAllStatesUI()
        containerHeight.isActive = false
        navigationView.isHidden = false
        mapView.userTrackingMode = .followWithHeading
        
        if let navInfo = navigationManager.getNavigationInfo() {
            updateNavInfo(navInfo)
        }
    }
    
    private func updateNavInfo(_ info: NavigationInfo) {
        navigationInfo.text = "Remaining distance: \(Int(info.remainingDistance))m"
    }
    
    @IBAction func stopNavigationTouched() {
        if case let .failure(error) = navigationManager.stopNavigation() {
            ToastHelper.showToast(message: "Failed to stop navigation with error - \(error)", onView: view)
        }
    }
    
    func navigationManager(_: NavigationManager, didUpdateNavigationInfo info: NavigationInfo) {
        updateNavInfo(info)
    }
    
    func navigationManager(_: NavigationManager, didStopNavigation navigation: Navigation) {
        renderItinerary(navigation.itinerary)
        ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func navigationManager(_: NavigationManager, didArriveAtDestination _: Navigation) {
        ToastHelper.showToast(message: "Navigation didArriveAtDestination", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }
    
    func navigationManager(_: NavigationManager, didFailWithError error: Error) {
        ToastHelper.showToast(message: "Navigation failed with error - \(error)", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
        if let currentItinerary {
            renderItinerary(currentItinerary)
        }
    }
    
    func navigationManager(_: NavigationManager, didRecalculateNavigation navigation: Navigation) {
        ToastHelper.showToast(message: "Navigation recalculated - \(navigation)", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }
    
    // MARK: - Misc
    
    private func hideAllStatesUI() {
        containerHeight.isActive = true
        poiView.isHidden = true
        poiInfo.text = nil
        itineraryView.isHidden = true
        itineraryInfo.text = nil
        navigationView.isHidden = true
        navigationInfo.text = nil
    }
    
    // MARK: - Permissions
    
    private func checkPermissions() -> AnyPublisher<Void, Error> {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        case .denied, .restricted:
            AlertFactory.presentSimpleAlert(
                message: "In order to be localized, we need to use your camera. Please go to app settings and accept camera permission",
                errorMessage: "User denied to go to settings and accept camera permission", on: self
            ).map { [unowned self] in
                openAppSettings() // it will force app restart, so no need for the furter actions
            }
            .eraseToAnyPublisher()
        case .notDetermined:
            showAlertAndRequestPermissions()
        @unknown default:
            showAlertAndRequestPermissions()
        }
    }
    
    private func showAlertAndRequestPermissions() -> AnyPublisher<Void, Error> {
        AlertFactory.presentSimpleAlert(
            message: "In order to be localized, we will use your camera. Please accept following permissions",
            errorMessage: "User refused to review permissions", on: self
        ).flatMap { [unowned self] in
            requestPermissions()
        }
        .eraseToAnyPublisher()
    }
    
    private func requestPermissions() -> AnyPublisher<Void, Error> {
        Deferred {
            Future { promise in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if !granted {
                        promise(.failure(NSError(domain: "User denied camera permission", code: 0, userInfo: nil)))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    private func openAppSettings() {
        let app = UIApplication.shared
        guard let url = URL(string: UIApplication.openSettingsURLString), app.canOpenURL(url) else {
            return
        }
        app.open(url)
    }
}

// MARK: - MLNMapViewDelegate

extension VPSViewController: MLNMapViewDelegate {
    
    func mapView(_: MLNMapView, didChange _: MLNUserTrackingMode, animated _: Bool) {
        updateLocateMeButtonIcon()
    }
    
    func mapView(_: MapView, didTouchAtPoint _: CGPoint) {
        // unselect POI only if there is no itinerary preview or active navigation
        if !navigationManager.hasActiveNavigation, currentItinerary == nil {
            _ = pointOfInterestManager.unselectPOI()
        }
    }
}

// swiftlint:enable file_length
