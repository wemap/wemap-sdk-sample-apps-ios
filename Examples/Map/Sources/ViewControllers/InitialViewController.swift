//
//  InitialViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 28/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import CoreLocation
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK

class InitialViewController: UIViewController {

    @IBOutlet var mapIDTextField: UITextField!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapIDTextField.text = "\(Constants.mapID)"
        
        // if you need to retrieve all points of interest for some map in advance
//        let service = PointOfInterestService()
//
//        service
//            .pointsOfInterestList(mapID: 23254)
//            .subscribe(onSuccess: {
//                debugPrint("received pois - \($0)")
//            }, onFailure: {
//                debugPrint("failed to receive pois with error - \($0)")
//            })
//            .disposed(by: disposeBag)
    }
    
    @IBAction func showMap() {
        
        guard let text = mapIDTextField.text, let id = Int(text) else {
            fatalError("Failed to get int ID from - \(String(describing: mapIDTextField.text))")
        }
        
        // uncomment if you want to use dev environment
//        WemapMap.setEnvironment(.dev)
        
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
        
        // swiftlint:disable:next force_cast
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "samplesTVC") as! SamplesTableViewController
        vc.mapData = mapData
        
        show(vc, sender: nil)
    }
}
