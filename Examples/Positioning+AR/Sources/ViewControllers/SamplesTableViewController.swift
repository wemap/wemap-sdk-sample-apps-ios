//
//  SamplesTableViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 19/05/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import SwiftUI
import UIKit
import WemapCoreSDK
import WemapPositioningSDKVPSARKit

class SamplesTableViewController: UITableViewController {

    /**
     The samples reached from a row rather than a segue, keyed by their cell's reuse identifier.

     A row rather than a storyboard scene: a scene naming a class needs a `customClass`, and that fails when
     the scene is *instantiated* rather than when the app is built — the worse of the two failures.
     */
    private enum RowSample: String, CaseIterable {
        case geoARSwiftUI = "geoARSwiftUICell"

        var title: String {
            switch self {
            case .geoARSwiftUI: "AR in SwiftUI"
            }
        }
    }

    var session: CoreSession!

    // MARK: - Navigation

    /**
     Two separate things can stop the VPS sample, and they need telling apart: the **device** may not support
     ARKit world tracking, and the **map** may not be set up for VPS.
     */
    override func shouldPerformSegue(withIdentifier identifier: String, sender _: Any?) -> Bool {

        guard identifier == "VPS" else {
            return true
        }

        let message: String? = if !VPSARKitLocationSource.isAvailable {
            "VPS location source is unavailable on this device"
        } else if !session.isVPSEnabled {
            "This map(\(session.mapID)) is not compatible with VPS Location Source"
        } else {
            nil
        }

        guard let message else {
            return true
        }

        AlertFactory.presentInfoAlert(message: message, on: self)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        return false
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {

        if let arController = segue.destination as? GeoARViewController {
            arController.session = session
        }

        guard let genericLSController = segue.destination as? GenericLSViewController else {
            return
        }

        genericLSController.locationSourceId = switch segue.identifier {
        case "Simulator": 0
        case "GPS": 1
        default: fatalError("Unknown segue identifier")
        }
    }

    /**
     The SwiftUI screen is handed the session, the same as a segue's destination — the map id is the one
     entered on the first screen.
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let identifier = tableView.cellForRow(at: indexPath)?.reuseIdentifier,
              let sample = RowSample(rawValue: identifier) else {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        let controller: UIViewController = switch sample {
        case .geoARSwiftUI: UIHostingController(rootView: GeoARSwiftUIScreen(session: session))
        }
        controller.title = sample.title

        let navigation = UINavigationController(rootViewController: controller)
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak navigation] _ in navigation?.dismiss(animated: true) }
        )
        present(navigation, animated: true)
    }
}
