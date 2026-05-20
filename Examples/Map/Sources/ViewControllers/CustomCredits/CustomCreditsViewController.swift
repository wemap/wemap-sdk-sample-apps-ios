//
//  CustomCreditsViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 07/05/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import MapLibre
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class CustomCreditsViewController: UIViewController {

    var mapData: MapData!

    private var mapView: MapView!

    private let closeButton: UIButton = {
        let button = UIButton(type: .close)
        button.setTitle("Close", for: .normal)
        return button
    }()

    private let dummyButton: UIButton = {
        let button = UIButton(type: .contactAdd)
        button.setTitle("Dummy", for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
        closeButton.addTarget(self, action: #selector(closeButtonTouched), for: .touchUpInside)

        view.addSubview(dummyButton)
        dummyButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dummyButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            dummyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        createMapView(mapData: mapData)
    }

    private func createMapView(mapData: MapData) {
        mapView = NavigationMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.mapDelegate = self
        mapView.mapData = mapData
        view.insertSubview(mapView, at: 0)
    }

    private func lateInit() {
        mapView.attributionButton.accessibilityLabel = "En savoir plus sur la cartographie de cette gare"

        view.accessibilityElements = [
            closeButton,
            dummyButton,
            mapView.attributionButton
        ]
    }

    @objc func closeButtonTouched() {
        dismiss(animated: true)
    }
}

extension CustomCreditsViewController: MapViewDelegate {

    func mapViewLoaded(_: MapView, style _: MLNStyle, data _: MapData) {
        lateInit()
    }
}
