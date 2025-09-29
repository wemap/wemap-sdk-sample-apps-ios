//
//  SimulatorLSViewController.swift
//  Positioning+ARExample
//
//  Created by Evgenii Khrushchev on 28/05/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import RxSwift
import WemapCoreSDK
import WemapGeoARSDK

final class SimulatorLSViewController: GeoARViewController {
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    
    private var simulator: SimulatorLocationSource {
        locationManager.locationSource as! SimulatorLocationSource // swiftlint:disable:this force_cast
    }
    
    private var pointOfInterestManager: ARPointOfInterestManaging { arView.pointOfInterestManager }
    private var selectedPOI: PointOfInterest? { pointOfInterestManager.getSelectedPOI() }
    
    override func geoARViewLoaded(_: GeoARView, mapData: MapData) {
        locationManager.locationSource = SimulatorLocationSource(mapData: mapData, options: .init(altitude: 1.6))
        simulator.setCoordinates([ARGlobals.origin], sample: false)
        navigationManager.delegate = self
        pointOfInterestManager.delegate = self
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
                onSuccess: { [unowned self] navigation in
                    simulator.setItinerary(navigation.itinerary)
                    updateNavButtons()
                },
                onFailure: { [unowned self] in
                    debugPrint("failed to start navigation with error - \($0)")
                    updateNavButtons()
                }
            )
            .disposed(by: disposeBag)
    }
    
    @IBAction func stopNavigation() {
        switch navigationManager.stopNavigation() {
        case .success:
            updateNavButtons()
            simulator.reset()
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

extension SimulatorLSViewController: NavigationManagerDelegate {
    
    func navigationManager(_: NavigationManager, didStopNavigation _: Navigation) {
        updateNavButtons()
        simulator.reset()
    }
}

extension SimulatorLSViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest _: PointOfInterest) {
        updateNavButtons()
    }
    
    func pointOfInterestManager(_: PointOfInterestManager, didUnselectPointOfInterest _: PointOfInterest) {
        updateNavButtons()
    }
}
