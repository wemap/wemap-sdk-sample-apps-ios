//
//  LevelsViewController.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//
// swiftlint:disable force_try

import Mapbox
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class LevelsViewController: MapViewController {
    
    private lazy var consumerData: [ConsumerData] = {
        let dataURL = Bundle.main.url(forResource: "consumer_data", withExtension: "json")!
        let data = try! Data(contentsOf: dataURL)
        return try! JSONDecoder().decode([ConsumerData].self, from: data)
    }()
    
    private var pointOfInterestManager: PointOfInterestManager {
        map.pointOfInterestManager
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.userTrackingMode = .followWithHeading
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func firstTouched() {
        selectPOI(with: consumerData[0])
    }
    
    @IBAction func secondTouched() {
        selectPOI(with: consumerData[1])
    }
    
    private func selectPOI(with consumerData: ConsumerData) {
        
        guard let desiredPOI = pointOfInterestManager.getPOIs().first(where: { $0.customerID == consumerData.externalID }) else {
            return debugPrint("POI with id - \(consumerData.externalID) has not been found in POIs")
        }
        
        pointOfInterestManager.selectPOI(desiredPOI)
        
        showToast(poiID: desiredPOI.id) {
            self.pointOfInterestManager.unselectPOI(desiredPOI)
        }
    }
    
    private func showToast(poiID: Int, onDismiss: (() -> Void)? = nil) {
        ToastHelper.showToast(
            message: "POI selected with id - \(poiID)",
            onView: view,
            hideDelay: 5,
            onDismiss: onDismiss
        )
    }
}

// swiftlint:enable force_try
