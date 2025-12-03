//
//  InitialViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 28/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKPolestar
import WemapPositioningSDKVPSARKit

final class InitialViewController: UIViewController {

    @IBOutlet var mapIDTextField: UITextField!
    @IBOutlet var sourcePicker: UIPickerView!
    @IBOutlet var loadMapButton: UIButton!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // uncomment if you want to use dev environment
//        WemapCore.setEnvironment(.dev)
//        WemapCore.setItinerariesEnvironment(.dev)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        mapIDTextField.text = "\(Constants.mapID)"
        
        let locationSourceTitles = LocationSourceType.allCases.map(\.name)
        
        Driver
            .of(locationSourceTitles)
            .drive(sourcePicker.rx.itemTitles) { _, element in element }
            .disposed(by: disposeBag)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func showMap() {
        
        let locationSourceType = LocationSourceType(rawValue: sourcePicker.selectedRow(inComponent: 0))
        
        let isAvailable = switch locationSourceType {
        case .simulator: SimulatorLocationSource.isAvailable
        case .polestar, .polestarEmulator: PolestarLocationSource.isAvailable
        case .vps: VPSARKitLocationSource.isAvailable
        case .systemDefault, .none: true
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

        loadMapButton.isEnabled = false

        WemapMap.shared
            .getMapData(mapID: id, token: Constants.token)
            .subscribe(onSuccess: {
                self.showMap($0)
            }, onFailure: {
                ToastHelper.showToast(message: "Failed to get style URL with error - \($0)", onView: self.view)
            }, onDisposed: {
                self.loadMapButton.isEnabled = true
            })
            .disposed(by: disposeBag)
    }
    
    private func showMap(_ mapData: MapData) {
        
        SettingsBundleHelper.applySettings(customKeysAndValues: customKeysAndValues())

        let locationSourceType = LocationSourceType(rawValue: sourcePicker.selectedRow(inComponent: 0))

        if locationSourceType == .vps && mapData.extras?.vpsEndpoint == nil {
            ToastHelper.showToast(message: "This map(\(mapData.id)) is not compatible with VPS Location Source", onView: view)
            return
        }

        let vc: UIViewController
        if locationSourceType == .vps {
            // swiftlint:disable:next force_cast
            let vpsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "vpsVC") as! VPSViewController
            vpsVC.mapData = mapData
            vc = vpsVC
        } else {
            // swiftlint:disable:next force_cast
            let navVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "navigationVC") as! NavigationViewController
            navVC.mapData = mapData
            navVC.locationSourceType = locationSourceType
            vc = navVC
        }

        show(vc, sender: nil)
    }
}
