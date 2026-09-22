//
//  MapSwiftUIScreen.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 03/08/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import MapLibre
import SwiftUI
import WemapCoreSDK
import WemapMapSDK

/**
 The map, its bindings and its events in one SwiftUI screen, and nothing else.

 Handed the session the samples table already loaded, like every other sample here — the map id is the one
 entered on the first screen.

 Deliberately minimal: the subject is the map's own SwiftUI surface, bindings and events, and anything
 layered on top would only obscure it.
 */
struct MapSwiftUIScreen: View {

    let session: MapSession

    /** A handle, not view state — declared in the same view as the `Map` so it dies with it */
    @State private var map: MapView?

    @State private var trackingMode: MLNUserTrackingMode = .none
    @State private var activeLevel: Level?
    @State private var selectedPOIs: Set<PointOfInterest> = []
    @State private var focusedBuilding: Building?
    @State private var navigationInfo: NavigationInfo?
    @State private var camera = MapCameraState(center: .init(latitude: 43.6, longitude: 3.9), zoom: 15)
    @State private var toast: String?

    /**
     The map runs edge to edge under the navigation bar, the way a `MapView` does on the UIKit samples — a
     SwiftUI screen is laid out inside the safe area unless it says otherwise, which leaves a blank strip
     where the other samples show map through the bar. Only the map gives the top inset up; the controls
     below keep theirs.
     */
    var body: some View {
        VStack {
            Map(session: session)
                .onLoaded { map = $0 }
                .onFailed { toast = "Failed to load the map — \($0.localizedDescription)" }
                .onTouch { point in print("Touched the map at \(point)") }
                .onProxyUpdate { proxy in print("Camera settled at \(proxy.camera.center)") }
                .focusedBuilding($focusedBuilding)
                .navigationInfo($navigationInfo)
                .userTrackingMode($trackingMode)
                .selectedPOIs($selectedPOIs)
                .camera($camera)
                .activeLevel($activeLevel)
                .ignoresSafeArea(edges: .top)

            // Reads and writes the same state, so it stays correct when the SDK drops tracking because the user panned
            Button {
                trackingMode = trackingMode.isFollowing ? .none : .followWithHeading
            } label: {
                Image(systemName: trackingMode.isFollowing ? "location.fill" : "location")
            }

            if let building = focusedBuilding, let activeLevel {
                Text("\(building.name) — \(activeLevel.name)")
                    .font(.caption)
            }

            if let navigationInfo {
                Text("\(Int(navigationInfo.remainingDistance)) m left")
            }

            Text(String(format: "Camera: %.4f, %.4f @ z%.1f",
                        camera.center.latitude, camera.center.longitude, camera.zoom))
                .font(.caption.monospaced())

            Button("Back to the entrance") {
                camera = MapCameraState(center: .init(latitude: 43.6, longitude: 3.9), zoom: 18)
            }

            Button("Clear selection") {
                selectedPOIs = []
            }
            .disabled(selectedPOIs.isEmpty)
        }
        // On the stack rather than on the map, so the toast is not clipped by the map's `ignoresSafeArea`
        // and reads over the controls as well.
        .sampleToast($toast)
    }
}
