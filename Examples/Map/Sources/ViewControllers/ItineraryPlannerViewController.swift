//
//  ItineraryPlannerViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK
import WemapMapSDK
import WemapMapWidgetsSDK

/**
 Planning an itinerary and then navigating it, which is the flow a maps app has:
 **plan → preview → start → stop**.

 The planning half is entirely the SDK's `ItineraryFormController` — picking the two ends, resolving the
 user's position, resolving the level of a point picked on the map, computing, drawing and framing. What is
 left for a screen is the three buttons below, and handing the previewed itinerary to the navigation manager.

 It is the one UIKit sample of the itinerary form; the levels rail it shows is the one every map sample
 gets from `MapViewController`.
 */
final class ItineraryPlannerViewController: MapViewController {

    typealias Delay = UIConstants.Delay

    @IBOutlet var planItineraryButton: UIButton!
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!

    private var simulator: SimulatorLocationSource? {
        map.userLocationManager.locationSource as? SimulatorLocationSource
    }

    private var navigationManager: MapNavigationManaging {
        map.navigationManager
    }

    private var itineraryForm: ItineraryFormController?

    /**
     The itinerary the form last drew — what `Start navigation` navigates along, so that the navigation
     follows exactly the line the user was shown instead of a fresh search that may answer differently.
     */
    private var previewedItinerary: Itinerary?

    private var observationTasks: [Task<Void, Never>] = []

    /**
     `updateUI()` is here rather than in `viewDidLoad()`: it asks the navigation manager whether a navigation
     is running, and the managers do not exist until the map has loaded - `MapView.navigationManager` traps
     before that. The storyboard starts all three buttons disabled, which is the right pre-load state anyway.
     */
    override func lateInit() {
        super.lateInit()
        updateUI()
        observeManagers()
        printSearchRuleNames()
    }

    private func observeManagers() {
        let selectionUpdates = pointOfInterestManager.selectionUpdates
        observationTasks = [
            Task { [weak self] in
                for await update in selectionUpdates {
                    guard let self else {
                        return
                    }
                    let message = "POI(s) selected with id(s) - \(update.selected.map(\.id))"
                    ToastHelper.showToast(message: message, onView: view, hideDelay: Delay.short)
                }
            }
        ]
        observationTasks += observeNavigation(infoLabel: navigationInfo) { [weak self] _ in
            self?.updateUI()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        for task in observationTasks {
            task.cancel()
        }
        observationTasks.removeAll()
    }

    @IBAction func planItineraryTouched() {
        presentItineraryForm()
    }

    @IBAction func startNavigationTouched() {

        guard let itinerary = previewedItinerary else {
            return
        }

        startNavigationButton.isEnabled = false

        // The form's switch is the only place the user expressed this, and these rules are what a
        // recalculation on the way will use - so a navigation started from a wheelchair-accessible preview has
        // to carry the constraint forward or it can quietly lose it at the first recalculation.
        let rules: ItinerarySearchRules = itineraryForm?.isWheelchairAccessible == true ? .wheelchair : .init()

        Task {
            do {
                let navigation = try await navigationManager.startNavigation(
                    itinerary, options: globalNavigationOptions, searchRules: rules,
                    itineraryOptions: globalItineraryOptions
                )
                simulator?.setItinerary(navigation.itinerary)
                // Only after the navigation has taken the drawn itinerary over: `addNavigation` reuses the
                // line the form already drew and restyles it, which leaves the form's `detach()` with nothing
                // to erase. Detaching first would instead erase it and make the navigation redraw the same
                // geometry from scratch.
                dismissItineraryForm()
            } catch {
                updateUI()
                ToastHelper.showToast(
                    message: "Failed to start navigation along the planned itinerary with error - \(error)",
                    onView: view, hideDelay: Delay.long
                )
            }
        }
    }

    @IBAction func stopNavigation() {
        let result = navigationManager.stopNavigation()
        switch result {
        case .success:
            simulator?.reset()
        case let .failure(error):
            ToastHelper.showToast(message: "Failed to stop navigation with error - \(error)", onView: view, hideDelay: Delay.long)
        }
    }

    /**
     The form is created per presentation rather than kept, because `detach()` is what erases the itinerary it
     drew — so a form that outlived its card would keep a line on the map that nothing owns.
     */
    private func presentItineraryForm() {

        let form = ItineraryFormController(
            mapView: map,
            // The livemap way in: a user who already picked a POI is asking for directions *to it*, so the
            // selection seeds the end instead of being asked for again.
            destination: pointOfInterestManager.getSelectedPOI().map {
                ItineraryEndpoint(name: $0.name, coordinate: $0.coordinate)
            },
            itineraryOptions: globalItineraryOptions,
            onItineraries: { [weak self] itineraries in
                self?.previewedItinerary = itineraries.first
                self?.updateUI()
            },
            onFailure: { [weak self] failure in
                guard let self else {
                    return
                }
                // The form erases the line it had drawn, so the previewed itinerary is gone with it — left
                // set, *Start navigation* stays enabled for a route that is no longer on the map.
                previewedItinerary = nil
                updateUI()

                guard let retry = failure.retry else {
                    // Nothing to re-ask: the form's own *My position* button is still there, and tapping it
                    // again is the way to try again. So this is news rather than a decision, and news is
                    // what a toast is for.
                    ToastHelper.showToast(
                        message: "Failed to resolve your position - \(failure.error.localizedDescription)",
                        onView: view, hideDelay: Delay.long
                    )
                    return
                }
                presentFailure(failure.error, retry: retry)
            },
            onClose: { [weak self] in
                self?.dismissItineraryForm()
            }
        )
        // Placement and inset from the controller, and deliberately no height: the card grows as the form does
        // — focusing a field adds two buttons, and picking a point replaces the card altogether — and the
        // controller constrains that.
        form.attach(to: self, in: map, alignment: .top)
        itineraryForm = form

        updateUI()
    }

    /**
     Asks the user whether to compute the itinerary again.

     An alert rather than a toast, because there is a decision in it: the retry is only good while the
     question is unchanged, and an alert is answered before the form can be touched — a fading toast would
     take the way back off screen, leaving a form with both ends filled, no line, and nothing to press.
     */
    private func presentFailure(_ error: any Error, retry: @escaping @MainActor () -> Void) {
        let alert = UIAlertController(
            title: "Failed to plan the itinerary", message: error.localizedDescription, preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in retry() })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func dismissItineraryForm() {
        itineraryForm?.detach()
        itineraryForm = nil
        previewedItinerary = nil
        updateUI()
    }

    /**
     Clears the selection the way tapping empty map does everywhere else, since a selected POI is what the
     form opens with as its destination.

     Not while the form is up: it turns POI selection off for as long as it is presented, and a tap there is
     part of the panning a point pick is made of.
     */
    override func mapTouched(at _: CGPoint) {
        guard itineraryForm == nil else {
            return
        }
        _ = pointOfInterestManager.unselectPOI()
    }

    private func updateUI() {
        // The manager is the source of truth for this - a flag of our own would have to be kept in step with
        // navigations the SDK ends by itself, arrival being the obvious one.
        let isNavigating = navigationManager.hasActiveNavigation
        planItineraryButton.isEnabled = itineraryForm == nil && !isNavigating
        startNavigationButton.isEnabled = previewedItinerary != nil && !isNavigating
        stopNavigationButton.isEnabled = isNavigating
    }
}
