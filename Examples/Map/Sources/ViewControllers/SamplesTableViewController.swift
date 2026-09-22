//
//  SamplesTableViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 23/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import SwiftUI
import UIKit
import WemapMapSDK

class SamplesTableViewController: UITableViewController {

    /**
     The samples reached from a row rather than a segue, keyed by their cell's reuse identifier.

     Rows rather than storyboard scenes: a scene naming a class needs a `customClass`, and a `customClass` a
     target does not compile fails when the scene is *instantiated* rather than when the app is built — the
     worse of the two failures. Everything else about them is ordinary navigation, which is what the
     navigation controller in this storyboard is for.
     */
    private enum RowSample: String, CaseIterable {
        case map = "mapSwiftUICell"

        var title: String {
            switch self {
            case .map: "Map in SwiftUI"
            }
        }
    }

    var session: MapSession!
    var locationSourceType: LocationSourceType!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wemap Map SDK Samples"
        // The section carries no header now that the navigation bar names the screen, and a plain-style table
        // reserves room for one anyway: iOS 15's header top padding, plus the estimated header height that
        // stands in until the table asks for a header it will never get. Both have to go, or the list starts a
        // finger's width below the navigation bar.
        tableView.sectionHeaderTopPadding = 0
        tableView.sectionHeaderHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {

        guard let session else {
            fatalError("You have to successfully create MapSession first")
        }
        
        if let map = segue.destination as? MapViewController {
            map.session = session
            map.locationSourceType = locationSourceType
            map.mapViewConfig = makeMapViewConfig()
        } else if let vc = segue.destination as? CustomCreditsViewController {
            vc.session = session
        }
    }

    /**
     The SwiftUI screen is handed the session, the same as a segue's destination — the map id is the one
     entered on the first screen.

     Pushed, so the navigation bar's back button dismisses them and they need no close button of their own —
     the same as every sample reached by a `show` segue from this table.
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let identifier = tableView.cellForRow(at: indexPath)?.reuseIdentifier,
              let sample = RowSample(rawValue: identifier) else {
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        let controller: UIViewController = switch sample {
        case .map: UIHostingController(rootView: MapSwiftUIScreen(session: session))
        }
        controller.title = sample.title
        show(controller, sender: nil)
    }
}
