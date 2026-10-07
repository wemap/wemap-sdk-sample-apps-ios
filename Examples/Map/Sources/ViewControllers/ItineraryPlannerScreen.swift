//
//  ItineraryPlannerScreen.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 03/09/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import SwiftUI
import WemapCoreSDK
import WemapMapSDK
import WemapMapWidgetsSDK

/**
 Planning an itinerary on a map with **no location source at all** — the case the other samples cannot show,
 because they all set one on the way in.

 Nothing here asks for the user's position, so nothing starts CoreLocation and no authorization prompt
 appears. The form notices there is no position to offer and leaves *My position* out, which is why both ends
 are picked on the map. That is a supported way to use it rather than a degraded one: pick a start, pick a
 destination, and the itinerary between them is computed and drawn.

 It is also the shortest complete SwiftUI map screen in the app — a session, a `Map`, the levels rail and the
 planner.

 - Note: Enter an **indoor** map id on the first screen to see the interesting case, where a point picked
   inside a building routes on the level it was picked on rather than over the ground floor.
 */
struct ItineraryPlannerScreen: View {

    let session: MapSession

    @State private var camera = MapCameraState(center: .init(latitude: 43.6047, longitude: 3.8807), zoom: 17)
    @State private var isPlanning = true
    @State private var isWheelchairAccessible = false
    @State private var itineraries: [Itinerary] = []
    @State private var toast: String?
    @State private var failure: SampleFailure?

    /**
     The map runs edge to edge, under the navigation bar, the way a `MapView` does on the UIKit samples — a
     SwiftUI screen is laid out inside the safe area unless it says otherwise, which leaves a blank strip
     where the other samples show map through the bar.

     The consequence is the `GeometryReader`: everything placed *over* the map gives up the safe area with
     it, so the insets have to be read outside the view that ignores them and handed back to the widgets.
     That is what the form's `placement` closure is for.
     */
    var body: some View {
        GeometryReader { geometry in
            Map(session: session)
                .onFailed { toast = "Failed to load the map — \($0.localizedDescription)" }
                .camera($camera)
                .itineraryForm(
                    isPresented: $isPlanning,
                    // Bound so this screen can read what the user asked for — a navigation started from the
                    // result would have to pass the matching `ItinerarySearchRules` on.
                    isWheelchairAccessible: $isWheelchairAccessible,
                    // This screen binds the camera, so the form is handed that binding to frame the route
                    // through. Left out, the framing would be undone by the binding on the very next update.
                    camera: $camera,
                    onItineraries: { itineraries = $0 },
                    // Every failure the form has — the route that could not be computed, the position it could
                    // not resolve — arrives here and nowhere else: the widget draws none of them. A sample that
                    // printed it left the user looking at a form that had silently given up.
                    //
                    // Where it goes depends on whether there is anything to decide. A failure carrying a
                    // `retry` is a question, and a question goes in an alert: it cannot be missed, and it is
                    // answered before the form can be touched, so the retry cannot go stale in the user's
                    // hands. One with nothing to re-ask is only news, and news goes on the toast.
                    onFailure: { formFailure in
                        // The form erases the line it had drawn, so the readout describing it goes too.
                        itineraries = []

                        guard let retry = formFailure.retry else {
                            // Unreachable on this screen, which has no location source and so never offers
                            // *My position* — but it is the shape every app needs, because a failure with no
                            // way back must still be said out loud.
                            toast = "Failed to resolve your position — \(formFailure.error.localizedDescription)"
                            return
                        }
                        failure = SampleFailure(
                            message: "Failed to compute an itinerary — \(formFailure.error.localizedDescription)",
                            retry: retry
                        )
                    },
                    // The closure form applies no inset of its own, so this screen owns the card's
                    // placement outright — the spacing included.
                    placement: { card in
                        card
                            .padding(UIConstants.Inset.overlay)
                            .padding(.top, geometry.safeAreaInsets.top)
                    }
                )
                // Both host modifiers on one map: each returns the map with its widget over it, so they chain
                // with each other and with the map's own modifiers, in any order.
                .levelsSwitcher()
                .overlay(alignment: .bottom) {
                    if let itinerary = itineraries.first {
                        Text("\(Int(itinerary.distance)) m, \(Int(itinerary.duration / 60)) min")
                            .font(.caption)
                            .padding(8)
                            .background(.thinMaterial, in: Capsule())
                            .padding(.bottom, UIConstants.Inset.overlay)
                            .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                }
                .ignoresSafeArea()
                // A toast for news, an alert for a question — see `SampleFailureAlert`.
                .sampleToast($toast)
                .sampleFailureAlert($failure)
        }
    }
}
