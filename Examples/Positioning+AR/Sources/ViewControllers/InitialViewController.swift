//
//  InitialViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 19/05/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK

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
    
    @IBAction func loadMapTapped() {
        loadMap()
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

        let vc = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "samplesTVC") as! SamplesTableViewController // swiftlint:disable:this force_cast
        vc.session = session

        show(vc, sender: nil)
    }
}
