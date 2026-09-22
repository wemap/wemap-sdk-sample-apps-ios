//
//  VPSViewController.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 20/06/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//
// swiftlint:disable file_length

import ARKit
import MapLibre
import RealityKit
import UIKit
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKVPSARKit

// swiftlint:disable:next type_body_length
final class VPSViewController: UIViewController {

    typealias Delay = UIConstants.Delay
    typealias Inset = UIConstants.Inset
    
    var session: MapSession!

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
    
    private var pointOfInterestManager: MapPointOfInterestManaging { mapView.pointOfInterestManager }
    private var navigationManager: MapNavigationManaging { mapView.navigationManager }
    private var itineraryManager: ItineraryManager { mapView.itineraryManager }
    private var locationManager: UserLocationManager { mapView.userLocationManager }

    private var drawnItinerary: Itinerary? { itineraryManager.drawnItineraries.first }

    private let levelSwitch = LevelSwitch()

    private var arView: ARView?
    private var scanningTimerTask: Task<Void, Never>?
    private var observationTasks: [Task<Void, Never>] = []
    /** Separate from `observationTasks`, which `mapLoaded()` reassigns */
    private var mapTasks: [Task<Void, Never>] = []

    private weak var errorCameraToast: UILabel?
    private weak var vpsErrorCameraToast: UILabel?

    private var vpsLocationSource: VPSARKitLocationSource!
    private var rescanSuggested = false

    private let impreciseMessage = "Your location seems imprecise, you can scan again to refine your position if necessary"

    private lazy var haptic: UINotificationFeedbackGenerator? = AppConstants.enableHapticFeedback ? UINotificationFeedbackGenerator() : nil

    private weak var backgroundScanHint: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.configure(with: session, config: makeMapViewConfig())
        observeMap()

        // Out of the way of this screen's own bottom-trailing button stack. MapLibre defaults the
        // attribution to the bottom-trailing corner, and the SDK deliberately leaves it there.
        mapView.attributionButtonPosition = .bottomLeft
        
        cameraButton.layer.cornerRadius = 12
        localizeButton.layer.cornerRadius = 12
        
        // hidden until a building is focused — `bind` unhides it
        levelSwitch.isHidden = true
        levelSwitch.accessibilityIdentifier = "levelsControlId"

        mapView.addSubview(levelSwitch)
        NSLayoutConstraint.activate([
            levelSwitch.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
            levelSwitch.trailingAnchor.constraint(
                equalTo: mapView.trailingAnchor, constant: -UIConstants.Inset.overlay
            )
        ])

        updateLocateMeButtonIcon()
    }

    private func mapLoaded() {

        localizeButton.isEnabled = true
        mapView.mapLibreDelegate = self
        
        levelSwitch.bind(buildingManager: mapView.buildingManager)

        let selectionUpdates = pointOfInterestManager.selectionUpdates
        let locationErrors = locationManager.errors
        let locationUpdates = locationManager.coordinates
        observationTasks = [
            Task { [weak self] in
                for await update in selectionUpdates {
                    guard let self else {
                        return
                    }
                    if !update.unselected.isEmpty {
                        dismissPOI()
                    }
                    for poi in update.selected {
                        renderPOI(poi)
                    }
                }
            },
            Task { [weak self] in
                for await error in locationErrors {
                    guard let self else {
                        return
                    }
                    handleLocationError(error)
                }
            },
            Task { [weak self] in
                var iterator = locationUpdates.makeAsyncIterator()
                guard await iterator.next() != nil, let self else {
                    return
                }
                enableFollowIfNotAlreadyEnabled()
            }
        ]
        
        subscribeOnNavigationEvents()
    }

    private func observeMap() {
        let touchedPoints = mapView.touchedPoints
        mapTasks = [
            Task { [weak self] in
                do {
                    _ = try await self?.mapView.awaitLoaded()
                    self?.mapLoaded()
                } catch {
                    print("Failed to load map view with error - \(error)")
                }
            },
            Task { [weak self] in
                for await _ in touchedPoints {
                    guard let self else {
                        return
                    }
                    mapTouched()
                }
            }
        ]
    }

    private func mapTouched() {
        // unselect POI only if there is no itinerary preview or active navigation
        if !navigationManager.hasActiveNavigation, drawnItinerary == nil {
            _ = pointOfInterestManager.unselectPOI()
        }
    }

    private func subscribeOnNavigationEvents() {
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
                    updateNavInfo(info)
                }
            },
            Task { [weak self] in
                for await error in navigationErrors {
                    guard let self else {
                        return
                    }
                    handleNavigationError(error)
                }
            }
        ])
    }

    deinit {
        for task in observationTasks + mapTasks {
            task.cancel()
        }
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
                
                Task {
                    do {
                        try await AlertFactory.presentSimpleAlert(
                            message: message, errorMessage: "You decided to scan later",
                            positiveText: "Scan now", negativeText: "Scan later", on: self
                        )
                        startScan()
                        enableFollowIfNotAlreadyEnabled()
                    } catch {
                        toggleNextUserTrackingMode()
                        ToastHelper.showToast(message: "When you'll be ready to scan again - click on camera button", onView: view)
                    }
                }
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
        Task {
            do {
                try await checkLocationSource(message: message)
                startScan()
            } catch {
                ToastHelper.showToast(message: (error as NSError).domain, onView: view, hideDelay: Delay.short)
            }
        }
    }

    private func checkLocationSource(message: String) async throws {
        try await checkPermissions()
        try await askForScan(message: message)
        try createAndStartLocationSource()
    }

    private func createAndStartLocationSource() throws {
        if locationManager.locationSource is VPSARKitLocationSource {
            vpsLocationSource.start()
            return
        }

        vpsLocationSource = try VPSARKitLocationSource(session: session, config: makeVPSConfig())
        observeVPS(vpsLocationSource)
        locationManager.locationSource = vpsLocationSource
        vpsLocationSource.start()
        mapView.showsUserHeadingIndicator = true
    }

    private func observeVPS(_ source: VPSARKitLocationSource) {
        let states = source.states.dropFirst() // it replays current state on subsribe but we don't need it
        let scanStatuses = source.scanStatuses
        let backgroundScanStatuses = source.backgroundScanStatuses
        let userLocalizationUpdates = source.userLocalizationUpdates
        let cameraTrackingStates = source.cameraTrackingStates
        observationTasks += [
            Task { [weak self] in
                for await state in states {
                    guard let self else {
                        return
                    }
                    handleStateChange(state)
                }
            },
            Task { [weak self] in
                for await status in scanStatuses {
                    guard let self else {
                        return
                    }
                    handleScanStatusChange(status)
                }
            },
            Task { [weak self] in
                for await status in backgroundScanStatuses {
                    guard let self else {
                        return
                    }
                    handleBackgroundScanStatusChange(status)
                }
            },
            Task { [weak self] in
                for await update in userLocalizationUpdates {
                    guard let self else {
                        return
                    }
                    handleUserLocalization(update)
                }
            },
            Task {
                for await camera in cameraTrackingStates {
                    print("Tracking state - \(camera.trackingState)")
                }
            }
        ]
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
        scanningTimerTask?.cancel()
        scanningTimerTask = nil
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
    
    private func askForScan(message: String) async throws {
        try await AlertFactory.presentSimpleAlert(
            message: message, errorMessage: "User refused to open camera", positiveText: "Open camera", on: self
        )
    }
    
    private func positioningLost(reason: VPSARKitLocationSource.State.NotPositioningReason) {
        // use this if you want to hide blue dot completely instead of having last known position visible.
        // blue dot becomes gray be default when tracking is lost
//        mapView.showsUserLocation = false
        
        mapView.setUserTrackingMode(.none, animated: true, completionHandler: nil)
        haptic?.notificationOccurred(.error)
        if locationManager.lastCoordinate != nil {
            locateUser(message: "We lost your position. In order to relocalize you we will use your camera. \(reason)")
        }
    }
    
    private func handleLocationError(_ error: Error) {
        if cameraOverlay.isHidden {
            return print("LocationManager failed with error - \(error)")
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

    private func handleStateChange(_ state: VPSARKitLocationSource.State) {
        print("VPS state changed - \(state)")
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

    private func handleScanStatusChange(_ status: VPSARKitLocationSource.ScanStatus) {
        print("Scan status changed - \(status)")
        switch status {
        case .started:
            showCameraView(session: vpsLocationSource.session)
            createScanningTimer()
        case .stopped:
            closeCameraTouched()
        @unknown default:
            fatalError()
        }
    }

    private func handleBackgroundScanStatusChange(_ status: VPSARKitLocationSource.ScanStatus) {
        print("Background scan status changed - \(status)")
        showBackgroundScanHintIfNeeded()
    }

    private func handleUserLocalization(_ update: UserLocalizationUpdate) {
        guard !update.backgroundScan || vpsLocationSource.state.isDegraded else {
            return
        }
        haptic?.notificationOccurred(.success)
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
        scanningTimerTask?.cancel()
        scanningTimerTask = Task {
            do {
                try await Task.sleep(nanoseconds: 20_000_000_000)
                await askToContinue()
            } catch {
                // no-op
            }
        }
    }

    private func askToContinue() async {
        do {
            try await AlertFactory.presentSimpleAlert(
                message: "We cannot localize you. Do you want to continue to try?", errorMessage: "You decided to get back to the map",
                positiveText: "Continue", negativeText: "Back to map", on: self
            )
            createScanningTimer()
        } catch {
            closeCameraTouched()
            ToastHelper.showToast(message: "Failed to localize you in reasonable time. Try again later", onView: view, hideDelay: Delay.long)
        }
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
    
    // MARK: - Itineraries
    
    @IBAction func computeItinerariesToPOI() {
        
        guard let selectedPOI = pointOfInterestManager.getSelectedPOI() else {
            return print("Can't compute itineraries, there is no selected POI")
        }
        
        if let origin = locationManager.lastCoordinate {
            calculateAndDrawItinerary(from: origin, to: selectedPOI.coordinate)
            return
        }
        
        Task {
            do {
                try await checkLocationSource(message: "We need to know your location to compute the best route. We will use your camera to localize you")
                startScan()
            } catch {
                ToastHelper.showToast(message: (error as NSError).domain, onView: view, hideDelay: Delay.short)
                return
            }

            let firstCoordinate: Coordinate
            let stream = locationManager.coordinates
            do {
                firstCoordinate = try await withTimeout(20) {
                    var iterator = stream.makeAsyncIterator()
                    return await iterator.next()!
                }
            } catch {
                let message = if error is WemapError {
                    "It took too long to localize you. Please try again"
                } else {
                    (error as NSError).domain
                }
                ToastHelper.showToast(message: message, onView: view, hideDelay: Delay.short)
                return
            }

            calculateAndDrawItinerary(from: firstCoordinate, to: selectedPOI.coordinate)
        }
    }
    
    private func calculateAndDrawItinerary(from: Coordinate, to: Coordinate) {
        let searchRules: ItinerarySearchRules = AppConstants.useWheelchair ? .wheelchair : .init()

        Task {
            do {
                let itineraries = try await itineraryManager
                    .computeItineraries(origin: from, destination: to, searchRules: searchRules)

                renderItinerary(itineraries.first!)
            } catch is CancellationError {
                return
            } catch {
                ToastHelper.showToast(message: "Failed to compute itineraries with error - \(error)", onView: view)
            }
        }
    }
    
    private func renderItinerary(_ itinerary: Itinerary) {

        guard itineraryManager.addItinerary(itinerary) else {
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
        guard itineraryManager.removeItinerary(drawnItinerary!) else {
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
        let options = ItineraryOptions(indoorLine: .init(color: .systemGreen))
        Task {
            do {
                _ = try await navigationManager
                    .startNavigation(drawnItinerary!, options: globalNavigationOptions, itineraryOptions: options)
            } catch {
                ToastHelper.showToast(message: "Failed to start navigation with error - \(error)", onView: view)
            }
        }
    }
    
    private func renderNavigation() {

        UIApplication.shared.isIdleTimerDisabled = true
        hideAllStatesUI()
        containerHeight.isActive = false
        navigationView.isHidden = false
        
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

    private func handleNavigationEvent(_ event: NavigationEvent) {
        switch event {
        case let .stopped(navigation): handleNavigationStopped(navigation)
        case .arrived: handleArrivalAtDestination()
        case let .recalculated(navigation): handleNavigationRecalculated(navigation)
        case .started: renderNavigation()
        @unknown default:
            fatalError()
        }
    }

    private func handleNavigationStopped(_ navigation: Navigation) {
        renderItinerary(navigation.itinerary)
        ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func handleArrivalAtDestination() {
        ToastHelper.showToast(message: "Navigation didArriveAtDestination", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }

    private func handleNavigationError(_ error: Error) {
        ToastHelper.showToast(message: "Navigation failed with error - \(error)", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
        if let drawnItinerary {
            renderItinerary(drawnItinerary)
        }
    }

    private func handleNavigationRecalculated(_ navigation: Navigation) {
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

    private func checkPermissions() async throws {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        case .denied, .restricted:
            try await AlertFactory.presentSimpleAlert(
                message: "In order to be localized, we need to use your camera. Please go to app settings and accept camera permission",
                errorMessage: "User denied to go to settings and accept camera permission", on: self
            )
            openAppSettings() // it will force app restart, so no need for the further actions
        case .notDetermined:
            try await showAlertAndRequestPermissions()
        @unknown default:
            try await showAlertAndRequestPermissions()
        }
    }

    private func showAlertAndRequestPermissions() async throws {
        try await AlertFactory.presentSimpleAlert(
            message: "In order to be localized, we will use your camera. Please accept following permissions",
            errorMessage: "User refused to review permissions", on: self
        )
        try await requestPermissions()
    }

    private func requestPermissions() async throws {
        try await withCheckedThrowingContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: NSError(domain: "User denied camera permission", code: 0))
                }
            }
        }
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

extension VPSViewController: @MainActor MLNMapViewDelegate {
    
    func mapView(_: MLNMapView, didChange _: MLNUserTrackingMode, animated _: Bool) {
        updateLocateMeButtonIcon()
    }
}

func withTimeout<T: Sendable>(
    _ timeout: TimeInterval, operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw WemapError.timeout
        }
        defer { group.cancelAll() }
        guard let result = try await group.next() else {
            throw WemapError.timeout
        }
        return result
    }
}

// swiftlint:enable file_length
