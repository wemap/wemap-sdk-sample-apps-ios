//
//  GeoARViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 03/07/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK
import WemapGeoARSDK

class GeoARViewController: UIViewController {
    
    var session: CoreSession!

    var arView: GeoARView {
        view as! GeoARView // swiftlint:disable:this force_cast
    }
    
    var navigationManager: ARNavigationManaging {
        arView.navigationManager
    }

    var locationManager: ARLocationManager {
        arView.locationManager
    }

    var pointOfInterestManager: ARPointOfInterestManaging {
        arView.pointOfInterestManager
    }

    private var loadTask: Task<Void, Never>?

    deinit {
        loadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        arView.configure(with: session, config: makeGeoARViewConfig())

        loadTask = Task { [weak self] in
            do {
                _ = try await self?.arView.awaitLoaded()
                self?.geoARLoaded()
            } catch {
                print("Failed to load the AR view with error - \(error)")
            }
        }
    }

    func geoARLoaded() {
        // for subclass overrides
    }
}
