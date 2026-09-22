//
//  InitialViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 28/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKVPSARKit

final class InitialViewController: UIViewController {

    @IBOutlet var mapIDTextField: UITextField!
    @IBOutlet var sourcePicker: UIPickerView!
    @IBOutlet var loadMapButton: UIButton!

    private let pickerSources: [LocationSourceType] = LocationSourceType.allCases
    private var locationSourceType: LocationSourceType? {
        .init(rawValue: sourcePicker.selectedRow(inComponent: 0))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sourcePicker.delegate = self
        sourcePicker.dataSource = self

        // Enable elapsed time prefix for testing
        Logger.elapsedTimePrefixEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)

        mapIDTextField.text = "\(Constants.mapID)"
    }

    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func showMap() {

        let isAvailable = switch locationSourceType {
        case .simulator: SimulatorLocationSource.isAvailable
        case .vps: VPSARKitLocationSource.isAvailable
        case .none, .systemDefault, .gps: true
        }

        guard isAvailable else {
            return showUnavailableAlert()
        }

        loadMap()
    }

    private func showUnavailableAlert(message: String = "Desired location source is unavailable on this device") {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func loadMap() {
        guard let text = mapIDTextField.text, let id = Int(text) else {
            fatalError("Failed to get int ID from - \(String(describing: mapIDTextField.text))")
        }

        SettingsBundleHelper.applySettings(customKeysAndValues: sdkVersions())

        loadMapButton.isEnabled = false
        Task {
            defer {
                loadMapButton.isEnabled = true
            }
            do {
                let session = try await MapSession(mapID: id, token: Constants.token, config: makeSessionConfig())
                showMap(session: session)
            } catch {
                print("Failed to create session with error - \(error)")
            }
        }
    }

    private func showMap(session: MapSession) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let usesVPS = locationSourceType == .vps
        if usesVPS, !session.isVPSEnabled {
            ToastHelper.showToast(message: "This map(\(session.mapID)) is not compatible with VPS Location Source", onView: view)
            return
        }

        let vc: UIViewController
        switch locationSourceType {
        case .vps:
            // swiftlint:disable:next force_cast
            let vpsVC = storyboard.instantiateViewController(withIdentifier: "vpsVC") as! VPSViewController
            vpsVC.session = session
            vc = vpsVC
        default:
            // swiftlint:disable:next force_cast
            let navVC = storyboard.instantiateViewController(withIdentifier: "navigationVC") as! NavigationViewController
            navVC.session = session
            navVC.locationSourceType = locationSourceType
            vc = navVC
        }
        show(vc, sender: nil)
    }
}

extension InitialViewController: UIPickerViewDataSource {

    func numberOfComponents(in _: UIPickerView) -> Int {
        1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        pickerSources.count
    }
}

extension InitialViewController: UIPickerViewDelegate {

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        pickerSources[row].name
    }
}
