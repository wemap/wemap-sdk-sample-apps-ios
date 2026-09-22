//
//  InitialViewController.swift
//  PosExample
//
//  Created by Evgenii Khrushchev on 28/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK
import WemapPositioningSDKVPSARKit

final class InitialViewController: UIViewController {

    @IBOutlet var mapIDTextField: UITextField!
    @IBOutlet var loadMapButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        mapIDTextField.text = "\(Constants.mapID)"
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func checkAvailability() {
        
        guard VPSARKitLocationSource.isAvailable else {
            return showUnavailableAlert()
        }
        
        loadMap()
    }
    
    private func showUnavailableAlert(message: String = "VPS location source is unavailable on this device") {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func loadMap() {
        guard let text = mapIDTextField.text, let id = Int(text) else {
            fatalError("Failed to get int ID from - \(String(describing: mapIDTextField.text))")
        }

        loadMapButton.isEnabled = false

        Task {
            defer { loadMapButton.isEnabled = true }
            do {
                let session = try await CoreSession(mapID: id, token: Constants.token, config: makeSessionConfig())
                showMap(session)
            } catch is CancellationError {
                return
            } catch {
                print("Failed to get map data with error - \(error)")
            }
        }
    }
    
    private func showMap(_ session: CoreSession) {

        SettingsBundleHelper.applySettings(customKeysAndValues: sdkVersions())

        guard session.isVPSEnabled else {
            let message = "This map(\(session.mapID)) is not compatible with VPS Location Source"
            ToastHelper.showToast(message: message, onView: view)
            return
        }

        let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "vpsViewController") as! VPSViewController // swiftlint:disable:this force_cast
        vc.session = session

        show(vc, sender: nil)
    }
}
