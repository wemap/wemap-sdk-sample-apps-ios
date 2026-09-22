//
//  GeoARSwiftUIScreen.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 03/08/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import SwiftUI
import WemapCoreSDK
import WemapGeoARSDK
import WemapPositioningSDKGPS

/**
 The AR view, its bindings and its events in one SwiftUI screen.

 Handed the session the samples table already loaded, like every other sample here — the map id is the one
 entered on the first screen.
 */
struct GeoARSwiftUIScreen: View {

    let session: CoreSession

    /** A handle, not view state — declared in the same view as the AR view so it dies with it */
    @State private var arView: GeoARView?

    @State private var userCoordinate: Coordinate?
    @State private var navigationInfo: NavigationInfo?
    @State private var selectedPOIs: Set<PointOfInterest> = []

    var body: some View {
        VStack {
            GeoAR(session: session)
                .onLoaded { view in
                    arView = view
                    // the AR scene cannot position itself without a location source
                    view.locationManager.locationSource = GPSLocationSource(session: session)
                }
                .onFailed { print("Failed to load the AR view with error - \($0)") }
                .userCoordinate($userCoordinate)
                .navigationInfo($navigationInfo)
                .selectedPOIs($selectedPOIs)

            if let userCoordinate {
                Text(String(format: "You: %.5f, %.5f", userCoordinate.latitude, userCoordinate.longitude))
                    .font(.caption.monospaced())
            }

            if let navigationInfo {
                Text("\(Int(navigationInfo.remainingDistance)) m left")
            }

            Button("Navigate to the selection") {
                guard let poi = selectedPOIs.first, let arView else {
                    return
                }
                Task {
                    _ = try? await arView.navigationManager.startNavigation(destination: poi.coordinate)
                }
            }
            .disabled(selectedPOIs.isEmpty)
        }
    }
}
