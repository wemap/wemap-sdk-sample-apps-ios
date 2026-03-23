//
//  InitialViewController.swift
//  PosExample
//
//  Created by Evgenii Khrushchev on 28/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Combine
import UIKit
import WemapCoreSDK
import WemapPositioningSDKVPSARKit

final class InitialViewController: UIViewController {

    @IBOutlet var mapIDTextField: UITextField!

    private let mapService = ServiceFactory.getMapService()

    private var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // uncomment if you want to use dev environment
//        WemapCore.setEnvironment(.dev)
//        WemapCore.setItinerariesEnvironment(.dev)
        
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
        
        cancellable = mapService
            .map(byID: id, token: Constants.token)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: {
                if case let .failure(error) = $0 {
                    debugPrint("Failed to get map data with error - \(error)")
                }
            }, receiveValue: {
                self.showMap($0)
            })
    }
    
    private func showMap(_ mapData: MapData) {
        
        SettingsBundleHelper.applySettings(customKeysAndValues: customKeysAndValues())

        guard mapData.extras?.vpsEndpoint != nil else {
            ToastHelper.showToast(message: "This map(\(mapData.id)) is not compatible with VPS Location Source", onView: view)
            return
        }

        // swiftlint:disable:next force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "vpsViewController") as! VPSViewController
        vc.mapData = mapData

        show(vc, sender: nil)
    }
}
