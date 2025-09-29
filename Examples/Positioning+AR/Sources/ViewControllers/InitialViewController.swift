//
//  InitialViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 19/05/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import RxSwift
import UIKit
import WemapCoreSDK
import WemapPositioningSDKVPSARKit

final class InitialViewController: UIViewController {
    
    @IBOutlet var mapIDTextField: UITextField!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // uncomment if you want to use dev environment
//        WemapCore.setEnvironment(.dev)
//        WemapCore.setItinerariesEnvironment(.dev)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        mapIDTextField.text = "22418"
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
        
        ServiceFactory
            .getMapService()
            .map(byID: id, token: Constants.token)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onSuccess: { mapData in
                self.showMap(mapData)
            }, onFailure: {
                debugPrint("Failed to get map data with error - \($0)")
            })
            .disposed(by: disposeBag)
    }
    
    private func showMap(_ mapData: MapData) {
        
        SettingsBundleHelper.applySettings(customKeysAndValues: customKeysAndValues())
        
        if #available(iOS 13.0, *) {
            // swiftlint:disable:next force_cast
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "samplesTVC") as! SamplesTableViewController
            vc.mapData = mapData
            
            show(vc, sender: nil)
        } else {
            showUnavailableAlert(message: "This sample supports only iOS 13 and higher")
        }
    }
}
