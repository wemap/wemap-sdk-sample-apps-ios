//
//  VPSLSViewController.swift
//  Positioning+ARExample
//
//  Created by Evgenii Khrushchev on 29/05/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import RxSwift
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
    
    private var pointOfInterestManager: ARPointOfInterestManaging { arView.pointOfInterestManager }
    
    private weak var currentVPSToast: UIView?
    
    override func geoARViewLoaded(_ arView: GeoARView, mapData: MapData) {
        locationManager.locationSource = VPSARKitLocationSource(mapData: mapData)
        vpsLocationSource.vpsDelegate = self
        handleStateChange(vpsLocationSource.state)
        arView.pointOfInterestManager.delegate = self
        arView.locationManager.delegate = self
        arView.navigationManager.delegate = self
    }
    
    @IBAction func startNavigation() {
        guard let selectedPOI = pointOfInterestManager.getSelectedPOI() else {
            return debugPrint("Failed to start navigation because selected POI is nil")
        }
        
        startNavigationButton.isEnabled = false
        
        navigationManager
            .startNavigation(destination: selectedPOI.coordinate)
            .subscribe(
                onSuccess: { [unowned self] navigation in
                    debugPrint("navigation started - \(navigation)")
                    stopNavigationButton.isEnabled = true
                },
                onFailure: { [unowned self] error in
                    debugPrint("failed to start navigation with error - \(error)")
                    startNavigationButton.isEnabled = true
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction func stopNavigation() {
        switch navigationManager.stopNavigation() {
        case .success:
            updateNavigationButtons()
        case let .failure(error):
            debugPrint("failed to stop navigation with error - \(error)")
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
        debugPrint("state - \(state)")

        switch state {
        case .notPositioning:
            debugPrint("scan required")
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

extension VPSLSViewController: VPSARKitLocationSourceDelegate {
    
    func locationSource(_: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
        handleStateChange(state)
    }
    
    func locationSource(_: VPSARKitLocationSource, didChangeScanStatus status: VPSARKitLocationSource.ScanStatus) {
        
        debugPrint("scan status - \(status)")
        
        switch status {
        case .started:
            startScanningButton.isEnabled = false
            stopScanningButton.isEnabled = true
        case .stopped:
            startScanningButton.isEnabled = true
            stopScanningButton.isEnabled = false
        }
        updateNavigationButtons()
    }
    
    private func showVPSToast(message: String) {
        currentVPSToast?.removeFromSuperview()
        currentVPSToast = ToastHelper.showToast(message: message, onView: view, hideDelay: .infinity)
    }
}

extension VPSLSViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest _: PointOfInterest) {
        startNavigationButton.isEnabled = true
    }
    
    func pointOfInterestManager(_: PointOfInterestManager, didUnselectPointOfInterest _: PointOfInterest) {
        startNavigationButton.isEnabled = false
    }
}

extension VPSLSViewController: ARLocationManagerDelegate {
    
    func locationManager(_: ARLocationManager, didFailWithError error: any Error) {
        debugPrint("LocationManager failed with error - \(error)")
    }
}

extension VPSLSViewController: NavigationManagerDelegate {
    
    func navigationManager(_: NavigationManager, didStopNavigation _: Navigation) {
        updateNavigationButtons()
    }
}
