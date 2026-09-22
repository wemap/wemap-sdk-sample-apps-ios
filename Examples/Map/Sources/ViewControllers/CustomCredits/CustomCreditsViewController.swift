//
//  CustomCreditsViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 07/05/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import UIKit
import WemapMapSDK

final class CustomCreditsViewController: UIViewController {

    private static let buttonSide: CGFloat = 44
    private static let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)

    var session: MapSession!

    private var mapView: MapView!
    private var loadTask: Task<Void, Never>?

    private lazy var dummyButton = makeOverlayButton(systemName: "plus", accessibilityLabel: "Bouton d'exemple")

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Custom credits"

        view.addSubview(dummyButton)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            dummyButton.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            dummyButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16)
        ])

        createMapView()
    }

    deinit {
        loadTask?.cancel()
    }

    private func createMapView() {
        mapView = CustomCreditsMapView(frame: view.bounds, session: session, config: makeMapViewConfig())
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(mapView, at: 0)

        loadTask = Task { [weak self] in
            do {
                _ = try await self?.mapView.awaitLoaded()
                self?.lateInit()
            } catch {
                print("Failed to load map view with error - \(error)")
            }
        }
    }

    private func lateInit() {
        customizeAttributionButton()

        // The compass appears in the top-trailing corner as soon as the map is rotated - where this screen
        // already put a button of its own.
        mapView.compassViewPosition = .bottomRight

        view.accessibilityElements = [
            dummyButton,
            mapView.attributionButton
        ]
    }

    /**
     Size, border and placement of the credits button are yours to change. Its visibility is not - the
     attribution has to stay on screen and tappable.
     */
    private func customizeAttributionButton() {

        let button = mapView.attributionButton

        button.accessibilityLabel = "En savoir plus sur la cartographie de cette gare"

        // MapLibre pins its own width/height constraints on the button - identified "width" and "height" -
        // and re-reads their constants every time it repositions the ornament. So a larger image on its own
        // never grows the button, and a second pair of constraints added next to those conflicts with them.
        let pinned = button.constraints.filter { $0.identifier == "width" || $0.identifier == "height" }
        if pinned.isEmpty {
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: Self.buttonSide),
                button.heightAnchor.constraint(equalToConstant: Self.buttonSide)
            ])
        } else {
            for constraint in pinned {
                constraint.constant = Self.buttonSide
            }
        }

        // After the size, never before: both setters below reinstall the constraints above from their
        // current constants. The default corner is bottom-trailing.
        mapView.attributionButtonPosition = .bottomLeft
        mapView.attributionButtonMargins = CGPoint(x: 16, y: 16)

        // The button is built once when the map view is created and never restyled, so this all survives.
        applyOverlayStyle(to: button, systemName: "info")

        // Resolve the new size now, so that a later reinstall measures the button as it is meant to look.
        mapView.layoutIfNeeded()
    }

    /**
     Every overlay control on this screen goes through this, the credits button owned by MapLibre included,
     so that they read as one set.
     */
    private func makeOverlayButton(systemName: String, accessibilityLabel: String) -> UIButton {

        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = accessibilityLabel
        applyOverlayStyle(to: button, systemName: systemName)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: Self.buttonSide),
            button.heightAnchor.constraint(equalToConstant: Self.buttonSide)
        ])

        return button
    }

    private func applyOverlayStyle(to button: UIButton, systemName: String) {

        button.setImage(UIImage(systemName: systemName, withConfiguration: Self.symbolConfiguration), for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = Self.buttonSide / 2
        button.layer.borderWidth = 1
        // A CGColor is resolved once - refresh it on a trait change if you support light and dark appearance.
        button.layer.borderColor = UIColor.separator.cgColor
        button.layer.masksToBounds = true
    }
}
