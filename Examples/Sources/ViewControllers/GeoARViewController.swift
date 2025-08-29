//
//  GEoARViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 03/07/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import RxSwift
import WemapGeoARSDK
import WemapCoreSDK

class GeoARViewController: UIViewController, GeoARViewDelegate {
    
    var mapData: MapData! {
        didSet { arView.mapData = mapData }
    }
    
    let disposeBag = DisposeBag()
    
    var arView: GeoARView {
        view as! GeoARView // swiftlint:disable:this force_cast
    }
    
    var navigationManager: ARNavigationManaging { arView.navigationManager }
    var locationManager: ARLocationManager { arView.locationManager }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.viewDelegate = self
    }
    
    func geoARViewLoaded(_: GeoARView, mapData _: MapData) {
        // no-op
    }
}
