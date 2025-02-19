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

class MapViewController: UIViewController, BuildingManagerDelegate, MapViewDelegate {
    
    var mapData: MapData!
    var locationSourceType: LocationSourceType!
    
    @IBOutlet var levelControl: UISegmentedControl!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.mapDelegate = self
        map.mapData = mapData
        
        levelControl.isHidden = true
        levelControl.accessibilityIdentifier = "levelsControlId"
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let initialBounds = map.mapData?.bounds.toCoordinateBounds() {
            let camera = map.cameraThatFitsCoordinateBounds(initialBounds)
            map.setCamera(camera, animated: true)
        }
    }
    
    @IBAction func levelChanged(_ sender: UISegmentedControl) {
        debugPrint("level changed - \(sender.selectedSegmentIndex)")
        focusedBuilding!.activeLevelIndex = sender.selectedSegmentIndex
    }
    
    // MARK: BuildingManagerDelegate
    
    func buildingManager(_: BuildingManager, didChangeLevel level: Level, ofBuilding building: Building) {
        debugPrint("\(#function) with \(level.id), of building \(building.name)")
        levelControl.selectedSegmentIndex = building.activeLevelIndex
    }
    
    func buildingManager(_: BuildingManager, didFocusBuilding building: Building?) {
        
        debugPrint("\(#function) with building \(building?.name ?? "nil")")
        
        guard let building else {
            levelControl.isHidden = true
            return
        }
        
        levelControl.removeAllSegments()
        let enumeratedLevels = building.levels.enumerated()
        for (index, level) in enumeratedLevels {
            levelControl.insertSegment(withTitle: level.shortName, at: index, animated: true)
        }
        levelControl.selectedSegmentIndex = building.activeLevelIndex
        levelControl.isEnabled = true
        levelControl.isHidden = false
    }
    
    func buildingManager(_: BuildingManager, didFailWithError error: any Error) {
        debugPrint("\(#function) with error \(error)")
    }
    
    func lateInit() {
        // camera bounds can be specified even if they don't exist in MapData
//        map.cameraBounds = maxBounds
        buildingManager.delegate = self
        buildingManager(buildingManager, didFocusBuilding: buildingManager.focusedBuilding)
        
        if locationManager.locationSource == nil {
            
            let source: LocationSource?
            switch locationSourceType {
            case .simulator: source = SimulatorLocationSource(options: .init(deviationRange: -20.0 ... 20.0))
#if canImport(WemapPositioningSDKPolestar)
            case .polestar: source = PolestarLocationSource(apiKey: Constants.polestarApiKey)
            case .polestarEmulator: source = PolestarLocationSource(apiKey: "emulator")
#endif
#if canImport(WemapPositioningSDKVPSARKit)
            case .vps: source = VPSARKitLocationSource(serviceURL: mapData.extras?.vpsEndpoint ?? Constants.vpsEndpoint)
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
