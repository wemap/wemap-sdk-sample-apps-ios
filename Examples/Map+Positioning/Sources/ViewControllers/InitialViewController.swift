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
import WemapMapSDK
import WemapPositioningSDKPolestar
import WemapPositioningSDKVPSARKit

class InitialViewController: UIViewController {

    @IBOutlet var mapIDTextField: UITextField!
    @IBOutlet var sourcePicker: UIPickerView!
    
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
        
        WemapMap.shared
            .getMapData(mapID: id, token: Constants.token)
            .subscribe(onSuccess: {
                self.showMap($0)
            }, onFailure: {
                debugPrint("Failed to get style URL with error - \($0)")
            })
            .disposed(by: disposeBag)
    }
    
    private func showMap(_ mapData: MapData) {
        if #available(iOS 13.0, *) {
            // swiftlint:disable:next force_cast
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "navigationVC") as! NavigationViewController
            vc.mapData = mapData
            vc.locationSourceType = LocationSourceType(rawValue: sourcePicker.selectedRow(inComponent: 0))
            
            show(vc, sender: nil)
        } else {
            showUnavailableAlert(message: "This sample supports only iOS 13 and higher")
        }
    }
}
