//
//  SamplesTableViewController.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 23/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import UIKit
import RxSwift
import WemapMapSDK

class SamplesTableViewController: UITableViewController {

    private var mapData: MapData?
        
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        WemapMap.shared
            .getStyleURL(withMapID: Constants.mapID, token: Constants.token)
            .subscribe(onSuccess: {
                self.mapData = $0
            }, onFailure: {
                debugPrint("Failed to get style URL with error - \($0)")
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let mapData, let styleURL = URL(string: mapData.style) else {
            fatalError("You have to successfully retrieve style URL first")
        }
        
        let map = segue.destination.view as! MapView
        map.styleURL = styleURL
        map.initialBounds = mapData.bounds
    }
}
