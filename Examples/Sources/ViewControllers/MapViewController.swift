//
//  MapViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 01/08/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import MapLibre
import RxSwift
import WemapCoreSDK
import WemapMapSDK
#if canImport(WemapPositioningSDKPolestar)
import WemapPositioningSDKPolestar
#endif
#if canImport(WemapPositioningSDKVPSARKit)
import WemapPositioningSDKVPSARKit
#endif
#if canImport(WemapPositioningSDKGPS)
import WemapPositioningSDKGPS
#endif

class MapViewController: UIViewController, MapViewDelegate {
    
    var mapData: MapData!
    var locationSourceType: LocationSourceType!
    
//    private let maxBounds = MLNCoordinateBounds(
//        sw: .init(latitude: 48.84045277048898, longitude: 2.371600716985739),
//        ne: .init(latitude: 48.84811619854466, longitude: 2.377353558713054)
//    )
    
    var map: MapView {
        view as! MapView // swiftlint:disable:this force_cast
    }
    
    var pointOfInterestManager: MapPointOfInterestManaging { map.pointOfInterestManager }
    var locationManager: UserLocationManager { map.userLocationManager }
    var buildingManager: BuildingManager { map.buildingManager }
    var focusedBuilding: Building? { buildingManager.focusedBuilding }
    var disposeBag = DisposeBag()
    
    private let levelSwitch = LevelSwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.mapDelegate = self
        map.mapData = mapData
        
        levelSwitch.isHidden = true
        levelSwitch.accessibilityIdentifier = "levelsControlId"
        
        map.addSubview(levelSwitch)
        NSLayoutConstraint.activate([
            levelSwitch.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            levelSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
        
        // to see coordinate returned by location source
//        weak var previous: UIView?
//        map.userLocationManager
//            .rx.coordinate
//            .subscribe(onNext: { [unowned self] in
//                previous?.removeFromSuperview()
//                previous = ToastHelper.showToast(message: "Location: \($0)", onView: view, hideDelay: 60, bottomInset: UIConstants.Inset.top)
//            })
//            .disposed(by: disposeBag)
    }
    
    @IBAction func levelChanged(_ sender: UISegmentedControl) {
        debugPrint("level changed - \(sender.selectedSegmentIndex)")
        focusedBuilding!.activeLevelIndex = sender.selectedSegmentIndex
    }
    
    func lateInit() {
        levelSwitch.bind(buildingManager: buildingManager)
        // camera bounds can be specified even if they don't exist in MapData
//        map.cameraBounds = maxBounds
        
        if locationManager.locationSource == nil {
            
            let source: LocationSource?
            switch locationSourceType {
            case .simulator: source = SimulatorLocationSource(mapData: mapData, options: .init(deviationRange: -20.0 ... 20.0))
#if canImport(WemapPositioningSDKPolestar)
            case .polestar: source = PolestarLocationSource(mapData: mapData, apiKey: Constants.polestarApiKey)
            case .polestarEmulator: source = PolestarLocationSource(mapData: mapData, apiKey: "emulator")
#endif
#if canImport(WemapPositioningSDKVPSARKit)
            case .vps: source = VPSARKitLocationSource(mapData: mapData)
#endif
#if canImport(WemapPositioningSDKGPS)
            case .gps: source = GPSLocationSource(mapData: mapData)
#endif
            default: source = nil
            }
            
            locationManager.locationSource = source
        }
    }
    
    func mapViewLoaded(_: MapView, style _: MLNStyle, data _: MapData) {
        lateInit()
        view.accessibilityIdentifier = "mapViewLoaded"
    }
    
    func mapView(_: MapView, didTouchAtPoint _: CGPoint) {
        // no-op
    }
}
