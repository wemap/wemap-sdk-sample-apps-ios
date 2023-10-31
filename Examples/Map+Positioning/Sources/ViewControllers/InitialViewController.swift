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

class InitialViewController: UIViewController {

    @IBOutlet var mapIDTextField: UITextField!
    @IBOutlet var sourcePicker: UIPickerView!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // uncomment if you want to use dev environment
//        WemapMap.setEnvironment(.dev)
        
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
        
        guard let text = mapIDTextField.text, let id = Int(text) else {
            fatalError("Failed to get int ID from - \(String(describing: mapIDTextField.text))")
        }
        
        WemapMap.shared
            .getStyleURL(withMapID: id, token: Constants.token)
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
            // Fallback on earlier versions
        }
    }
}
