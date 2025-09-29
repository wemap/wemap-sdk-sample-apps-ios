//
//  GPSLSViewController.swift
//  Positioning+ARExample
//
//  Created by Evgenii Khrushchev on 13/08/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import RxSwift
import WemapCoreSDK
import WemapGeoARSDK
import WemapPositioningSDKGPS

class GPSLSViewController: GeoARViewController {
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    
    private var pointOfInterestManager: ARPointOfInterestManaging { arView.pointOfInterestManager }
    private var selectedPOI: PointOfInterest? { pointOfInterestManager.getSelectedPOI() }
    
    private var toast: UIView?
    
    override func geoARViewLoaded(_ arView: GeoARView, mapData: MapData) {
        locationManager.locationSource = GPSLocationSource(mapData: mapData)
        arView.pointOfInterestManager.delegate = self
        
        toast = ToastHelper.showToast(message: "Searching for you location...", onView: view, hideDelay: .greatestFiniteMagnitude)
        locationManager
            .rx.coordinate
            .take(1)
            .subscribe(onNext: { [unowned self] _ in
                toast?.removeFromSuperview()
                toast = nil
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func startNavigation() {
        guard let selectedPOI else {
            updateNavButtons()
            return debugPrint("Failed to start navigation because selected POI is nil")
        }
        
        startNavigationButton.isEnabled = false
        
        navigationManager
            .startNavigation(destination: selectedPOI.coordinate)
            .subscribe(
                onSuccess: { [unowned self] _ in
                    updateNavButtons()
                },
                onFailure: { [unowned self] error in
                    debugPrint("failed to start navigation with error - \(error)")
                    updateNavButtons()
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction func stopNavigation() {
        switch navigationManager.stopNavigation() {
        case .success:
            updateNavButtons()
        case let .failure(error):
            debugPrint("failed to stop navigation with error - \(error)")
            updateNavButtons()
        }
    }
    
    @IBAction func close(_: UIButton) {
        dismiss(animated: true)
    }
    
    private func updateNavButtons() {
        let hasActiveNavigation = navigationManager.hasActiveNavigation
        startNavigationButton.isEnabled = selectedPOI != nil && !hasActiveNavigation
        stopNavigationButton.isEnabled = hasActiveNavigation
    }
}

extension GPSLSViewController: NavigationManagerDelegate {
    
    func navigationManager(_: NavigationManager, didStopNavigation _: Navigation) {
        updateNavButtons()
    }
}

extension GPSLSViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest _: PointOfInterest) {
        updateNavButtons()
    }
    
    func pointOfInterestManager(_: PointOfInterestManager, didUnselectPointOfInterest _: PointOfInterest) {
        updateNavButtons()
    }
}
