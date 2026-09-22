//
//  VPSLSViewController.swift
//  Positioning+ARExample
//
//  Created by Evgenii Khrushchev on 29/05/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK
import WemapGeoARSDK
import WemapPositioningSDKVPSARKit

final class VPSLSViewController: GeoARViewController {
    
    @IBOutlet var startScanningButton: UIButton!
    @IBOutlet var stopScanningButton: UIButton!
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    
    private var vpsLocationSource: VPSARKitLocationSource {
        locationManager.locationSource as! VPSARKitLocationSource // swiftlint:disable:this force_cast
    }
    
    private weak var currentVPSToast: UIView?

    private var observationTasks: [Task<Void, Never>] = []

    override func geoARLoaded() {
        do {
            locationManager.locationSource = try VPSARKitLocationSource(session: arView.session)
        } catch {
            print("Failed to create VPS location source: \(error)")
            return
        }
        handleStateChange(vpsLocationSource.state)

        let selectionUpdates = arView.pointOfInterestManager.selectionUpdates
        let navigationEvents = arView.navigationManager.navigationEvents
        let states = vpsLocationSource.states
        let scanStatuses = vpsLocationSource.scanStatuses
        let locationErrors = arView.locationManager.errors
        observationTasks = [
            Task { [weak self] in
                for await update in selectionUpdates {
                    guard let self else {
                        return
                    }
                    startNavigationButton.isEnabled = !update.allSelected.isEmpty
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
                    updateNavigationButtons()
                }
            },
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
            Task {
                for await error in locationErrors {
                    print("LocationManager failed with error - \(error)")
                }
            }
        ]
    }

    deinit {
        for task in observationTasks {
            task.cancel()
        }
    }
    
    @IBAction func startNavigation() {
        guard let selectedPOI = pointOfInterestManager.getSelectedPOI() else {
            return print("Failed to start navigation because selected POI is nil")
        }
        
        startNavigationButton.isEnabled = false

        Task {
            do {
                let navigation = try await navigationManager.startNavigation(destination: selectedPOI.coordinate)
                print("navigation started - \(navigation)")
                stopNavigationButton.isEnabled = true
            } catch {
                print("failed to start navigation with error - \(error)")
                startNavigationButton.isEnabled = true
            }
        }
    }
    
    @IBAction func stopNavigation() {
        switch navigationManager.stopNavigation() {
        case .success:
            updateNavigationButtons()
        case let .failure(error):
            print("failed to stop navigation with error - \(error)")
            if let navError = error as? NavigationError, case .noActiveNavigation = navError {
                updateNavigationButtons()
            }
        }
    }
    
    @IBAction func close(_: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func startScanning() {
        vpsLocationSource.startScan()
    }
    
    @IBAction func stopScanning() {
        vpsLocationSource.stopScan()
    }
    
    private func handleStateChange(_ state: VPSARKitLocationSource.State) {
        print("state - \(state)")

        switch state {
        case .notPositioning:
            print("scan required")
            startScanningButton.isEnabled = true
            currentVPSToast?.removeFromSuperview()
        case let .degradedPositioning(reason):
            showVPSToast(message: "Tracking is limited due to - \(reason)")
        default: // .accuratePositioning
            startNavigationButton.isEnabled = true
            currentVPSToast?.removeFromSuperview()
        }
    }
    
    private func updateNavigationButtons() {
        startNavigationButton.isEnabled = pointOfInterestManager.getSelectedPOI() != nil && !navigationManager.hasActiveNavigation
        stopNavigationButton.isEnabled = navigationManager.hasActiveNavigation
    }
}

extension VPSLSViewController {

    private func handleScanStatusChange(_ status: VPSARKitLocationSource.ScanStatus) {

        print("scan status - \(status)")

        switch status {
        case .started:
            startScanningButton.isEnabled = false
            stopScanningButton.isEnabled = true
        case .stopped:
            startScanningButton.isEnabled = true
            stopScanningButton.isEnabled = false
        @unknown default:
            fatalError()
        }
        updateNavigationButtons()
    }

    private func showVPSToast(message: String) {
        currentVPSToast?.removeFromSuperview()
        currentVPSToast = ToastHelper.showToast(message: message, onView: view, hideDelay: .infinity)
    }
}
