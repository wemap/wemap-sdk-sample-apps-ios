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
import WemapMapWidgetsSDK
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
    }

    override func viewDidDisappear(_ animated: Bool) {
        for task in lifecycleTasks {
            task.cancel()
        }
        lifecycleTasks.removeAll()
        super.viewDidDisappear(animated)
    }

    func lateInit() {
        installLevelsRail()

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
     Observes the navigation manager the way every navigating sample shows it: a toast for each event and
     error, the progress in `infoLabel`, and the steps printed when a navigation starts.

     - Parameters:
       - infoLabel: Shows the progress while a navigation runs; hidden otherwise.
       - onNavigatingChange: Called with whether a navigation is running, after it starts or stops, so a screen
         can update its buttons.
     - Returns: The observation tasks, for the screen to cancel along with its own.
     */
    final func observeNavigation(
        infoLabel: UILabel,
        onNavigatingChange: @escaping @MainActor @Sendable (Bool) -> Void
    ) -> [Task<Void, Never>] {
        // `final` and the spelled-out `@Sendable` are load-bearing: left to inference, the closure type mangled
        // differently in the subclasses' files than here, and every subclass failed to link.
        let navigationManager = map.navigationManager
        let navigationEvents = navigationManager.navigationEvents
        let navigationInfoUpdates = navigationManager.navigationInfoUpdates
        let navigationErrors = navigationManager.errors
        return [
            Task { [weak self, weak infoLabel] in
                for await event in navigationEvents {
                    guard let self, let infoLabel else {
                        return
                    }
                    handleNavigationEvent(event, infoLabel: infoLabel, onNavigatingChange: onNavigatingChange)
                }
            },
            Task { [weak infoLabel] in
                for await info in navigationInfoUpdates {
                    guard let infoLabel else {
                        return
                    }
                    infoLabel.isHidden = false
                    let nextStep = info.nextStep?.getNavigationInstructions().instructions ?? "no"
                    infoLabel.text = info.compactDescription + "\nNext - \(nextStep)"
                }
            },
            Task { [weak self] in
                for await error in navigationErrors {
                    guard let self else {
                        return
                    }
                    let message = "Navigation failed with error - \(error)"
                    ToastHelper.showToast(message: message, onView: view, hideDelay: UIConstants.Delay.short)
                }
            }
        ]
    }

    /** Prints the names of the search rules the map offers, which is what `ItinerarySearchRules` takes. */
    final func printSearchRuleNames() {
        let itineraryManager = map.itineraryManager
        Task {
            do {
                let ruleNames = try await itineraryManager.searchRuleNames()
                print("Available rule names - \(ruleNames)")
            } catch {
                print("Failed to get rule names with error - \(error)")
            }
        }
    }

    /**
     Installs the SDK's levels rail, which mirrors the building manager, hides itself while no building is
     focused and sizes itself; all that is left here is where it sits.

     Called from `lateInit()`, not `viewDidLoad()`: it needs `buildingManager`, which does not exist until the
     map has loaded. Nothing keeps a reference — `attach(to:in:alignment:)` makes the rail a child of this
     controller, and `children` is what owns it.
     */
    private func installLevelsRail() {

        let rail = LevelsSwitcherController(buildingManager: buildingManager, userLocationManager: locationManager)
        rail.view.accessibilityIdentifier = "levelsControlId"
        // The alignment overload places it where the SwiftUI modifier does — the theme's edge spacing in from
        // the map's safe area — so no sample has to name that number.
        rail.attach(to: self, in: map, alignment: .trailing)
    }

    private final func handleNavigationEvent(
        _ event: NavigationEvent,
        infoLabel: UILabel,
        onNavigatingChange: @MainActor @Sendable (Bool) -> Void
    ) {
        switch event {
        case let .started(navigation):
            infoLabel.isHidden = false
            ToastHelper.showToast(message: "Navigation started", onView: view)
            onNavigatingChange(true)
            for step in navigation.itinerary.legs.flatMap(\.steps) {
                print(step.getNavigationInstructions())
            }
        case .stopped:
            infoLabel.isHidden = true
            ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: UIConstants.Delay.short)
            onNavigatingChange(false)
        case .arrived:
            ToastHelper.showToast(
                message: "Arrived at destination", onView: view,
                hideDelay: UIConstants.Delay.short, bottomInset: UIConstants.Inset.mid
            )
        case let .recalculated(navigation):
            let message = "Navigation recalculated - \(navigation)"
            ToastHelper.showToast(message: message, onView: view, hideDelay: UIConstants.Delay.short)
        @unknown default:
            fatalError()
        }
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
