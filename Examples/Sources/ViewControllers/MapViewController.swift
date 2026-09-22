//
//  MapViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 01/08/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import MapLibre
import WemapCoreSDK
import WemapMapSDK
#if VPSARKIT
import WemapPositioningSDKVPSARKit
#endif
#if GPS
import WemapPositioningSDKGPS
#endif

class MapViewController: UIViewController {

    var session: MapSession!
    var locationSourceType: LocationSourceType!
    var mapViewConfig: MapViewConfig = .init()

    var map: MapView {
        view as! MapView // swiftlint:disable:this force_cast
    }

    var pointOfInterestManager: MapPointOfInterestManaging {
        map.pointOfInterestManager
    }

    var locationManager: UserLocationManager {
        map.userLocationManager
    }

    var buildingManager: BuildingManager {
        map.buildingManager
    }

    var focusedBuilding: Building? {
        buildingManager.focusedBuilding
    }

    var lifecycleTasks: [Task<Void, Never>] = []

    private lazy var levelSwitch = LevelSwitch()
    private var mapTasks: [Task<Void, Never>] = []

    deinit {
        for task in mapTasks {
            task.cancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        map.configure(with: session, config: mapViewConfig)
        observeMap()

        // to see coordinate returned by location source
//        weak var previous: UIView?
//        let coordinateStream = map.userLocationManager.coordinates
//        let task = Task { [weak view] in
//            for await coordinate in coordinateStream {
//                guard let view else {
//                    return
//                }
//                previous?.removeFromSuperview()
//                previous = ToastHelper.showToast(
//                    message: "Location: \(coordinate)", onView: view, hideDelay: 60, bottomInset: UIConstants.Inset.top
//                )
//            }
//        }
//        lifecycleTasks.append(task)
    }

    override func viewDidDisappear(_ animated: Bool) {
        for task in lifecycleTasks {
            task.cancel()
        }
        lifecycleTasks.removeAll()
        super.viewDidDisappear(animated)
    }

    func lateInit() {
        installLevelsSwitcher()

        guard locationManager.locationSource == nil else {
            return
        }

        switch locationSourceType {
        case .simulator:
            let rangeBound = CommonAppConstants.simulatorDeviationRange
            let simulationOptions: SimulationOptions = if rangeBound == 0 {
                .init()
            } else {
                .init(deviationRange: -rangeBound / 2 ... rangeBound / 2)
            }
            locationManager.locationSource = SimulatorLocationSource(session: session, options: simulationOptions)
#if VPSARKIT
        case .vps:
            do {
                locationManager.locationSource = try VPSARKitLocationSource(session: session)
            } catch {
                print("Failed to create VPS location source: \(error)")
            }
#endif
#if GPS
        case .gps:
            locationManager.locationSource = GPSLocationSource(session: session)
#endif
        default:
            break
        }
    }

    func mapLoaded() {
        lateInit()
        view.accessibilityIdentifier = "mapViewLoaded"
    }

    func mapLoadingFailed(error: any Error) {
        print("Failed to load mapView with error - \(error)")
    }

    func mapTouched(at _: CGPoint) {
        // for subclass overrides
    }

    /**
     Installs the samples' own levels rail.

     Called from `lateInit()`, not `viewDidLoad()`: it needs `buildingManager`, which does not exist until the
     map has loaded.

     A seam a sample can override to install a rail of its own, rather than something each screen builds:
     five controllers across three apps subclass this one, so anything installed here lands on every one
     of them.
     */
    func installLevelsSwitcher() {

        // hidden until a building is focused — `bind` unhides it, and there is nothing to switch before then
        levelSwitch.isHidden = true
        levelSwitch.accessibilityIdentifier = "levelsControlId"

        map.addSubview(levelSwitch)
        NSLayoutConstraint.activate([
            levelSwitch.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            levelSwitch.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UIConstants.Inset.overlay)
        ])

        levelSwitch.bind(buildingManager: buildingManager)
    }

    private func observeMap() {
        let touchedPoints = map.touchedPoints
        // deliberately not in `lifecycleTasks` — that array is cancelled on `viewDidDisappear` and reassigned by
        // subclasses, while these two live as long as the view controller, exactly as the old delegate did
        mapTasks = [
            Task { [weak self] in
                do {
                    _ = try await self?.map.awaitLoaded()
                    self?.mapLoaded()
                } catch {
                    self?.mapLoadingFailed(error: error)
                }
            },
            Task { [weak self] in
                for await point in touchedPoints {
                    guard let self else {
                        return
                    }
                    mapTouched(at: point)
                }
            }
        ]
    }
}
