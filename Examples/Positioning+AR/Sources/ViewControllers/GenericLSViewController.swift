//
//  GenericLSViewController.swift
//  Positioning+ARExample
//
//  Created by Evgenii Khrushchev on 28/05/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import CoreLocation
import UIKit
import WemapCoreSDK
import WemapGeoARSDK
import WemapPositioningSDKGPS

final class GenericLSViewController: GeoARViewController {

    var locationSourceId: Int = -1

    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!

    private var simulator: SimulatorLocationSource? {
        locationManager.locationSource as? SimulatorLocationSource
    }

    private var selectedPOI: PointOfInterest? {
        pointOfInterestManager.getSelectedPOI()
    }

    private var customPOIs: Set<PointOfInterest> = []

    private var direction: CLLocationDirection = -90
    private var toast: UIView?
    private var observationTasks: [Task<Void, Never>] = []

    override func geoARLoaded() {

        let selectionUpdates = pointOfInterestManager.selectionUpdates
        let navigationEvents = navigationManager.navigationEvents
        observationTasks = [
            Task { [weak self] in
                for await _ in selectionUpdates {
                    guard let self else {
                        return
                    }
                    updateNavButtons()
                }
            },
            Task { [weak self] in
                for await event in navigationEvents {
                    guard let self else {
                        return
                    }
                    guard case .stopped = event else {
                        continue
                    }
                    updateNavButtons()
                    simulator?.reset()
                }
            }
        ]

        locationManager.locationSource = switch locationSourceId {
        case 0: SimulatorLocationSource(session: arView.session, options: .init(altitude: 1.6))
        case 1: GPSLocationSource(session: arView.session)
        default: fatalError("Unsupported location source")
        }

        if let simulator {
            simulator.setCoordinates([Coordinate(coordinate2D: session.mapCenter)], sample: false)
        } else {
            toast = ToastHelper.showToast(message: "Searching for you location...", onView: view, hideDelay: .infinity)
            let stream = locationManager.coordinates
            Task {
                var iterator = stream.makeAsyncIterator()
                _ = await iterator.next()
                toast?.removeFromSuperview()
                toast = nil
            }
        }
    }
    
    @IBAction func startNavigation() {
        guard let selectedPOI else {
            updateNavButtons()
            ToastHelper.showToast(message: "Failed to start navigation because selected POI is nil", onView: view)
            return
        }
        
        startNavigationButton.isEnabled = false

        Task {
            do {
                let navigation = try await navigationManager.startNavigation(destination: selectedPOI.coordinate)
                simulator?.setItinerary(navigation.itinerary)
                updateNavButtons()
            } catch {
                ToastHelper.showToast(message: "Failed to start navigation with error - \(error)", onView: view)
                updateNavButtons()
            }
        }
    }
    
    @IBAction func stopNavigation() {
        switch navigationManager.stopNavigation() {
        case .success:
            updateNavButtons()
            simulator?.reset()
        case let .failure(error):
            ToastHelper.showToast(message: "Failed to stop navigation with error - \(error)", onView: view)
            updateNavButtons()
        }
    }

    @IBAction func addPOI() {
        guard let poi = generatePOI() else {
            ToastHelper.showToast(message: "Failed to generate POI", onView: view)
            return
        }
        if !pointOfInterestManager.addPOI(poi) {
            ToastHelper.showToast(message: "Failed to add POI - \(poi)", onView: view)
        } else {
            customPOIs.insert(poi)
        }
    }

    @IBAction func removePOI() {
        guard let poi = customPOIs.randomElement() else {
            ToastHelper.showToast(message: "There is no POI to remove", onView: view)
            return
        }

        if !pointOfInterestManager.removePOI(poi) {
            ToastHelper.showToast(message: "Failed to remove POI - \(poi)", onView: view)
        } else {
            customPOIs.remove(at: customPOIs.firstIndex(of: poi)!)
        }
    }

    @IBAction func addPOIs() {
        let pois = (0 ... 2).compactMap { _ in
            generatePOI()
        }
        guard !pois.isEmpty else {
            ToastHelper.showToast(message: "Failed to generate POIs", onView: view)
            return
        }
        if !pointOfInterestManager.addPOIs(Set(pois)) {
            ToastHelper.showToast(message: "Failed to add POIs", onView: view)
        } else {
            customPOIs.formUnion(pois)
        }
    }

    @IBAction func removePOIs() {
        guard !customPOIs.isEmpty else {
            ToastHelper.showToast(message: "There is POIs to remove", onView: view)
            return
        }

        if !pointOfInterestManager.removePOIs(customPOIs) {
            ToastHelper.showToast(message: "Failed to remove POIs", onView: view)
        } else {
            customPOIs.removeAll()
        }
    }

    @IBAction func close(_: UIButton) {
        dismiss(animated: true)
    }

    deinit {
        for task in observationTasks {
            task.cancel()
        }
    }

    private func generatePOI() -> PointOfInterest? {

        guard let userCoordinate = locationManager.lastCoordinate else {
            ToastHelper.showToast(message: "Failed to get user location", onView: view)
            return nil
        }

        let target = userCoordinate.coordinate(at: 50, facing: direction)
        direction += 15

        return .init(
            name: "Custom POI",
            coordinate: target,
            imageURL: "https://api.getwemap.com/images/pps-categories/icon_circle_maaap.png"
        )
    }

    private func updateNavButtons() {
        let hasActiveNavigation = navigationManager.hasActiveNavigation
        startNavigationButton.isEnabled = selectedPOI != nil && !hasActiveNavigation
        stopNavigationButton.isEnabled = hasActiveNavigation
    }
}
