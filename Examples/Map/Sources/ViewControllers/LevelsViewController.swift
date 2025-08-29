//
//  LevelsViewController.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK
import WemapMapSDK

final class LevelsViewController: MapViewController {
    
    private var uniqueLevels: Set<Float> = []
    
    private var pois: Set<PointOfInterest> { pointOfInterestManager.getPOIs() }
    
    override func lateInit() {
        super.lateInit()
        uniqueLevels = Set(pois.compactMap { $0.coordinate.levels.first })
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func firstTouched() {
        
        guard let minLevel = uniqueLevels.min() else {
            return debugPrint("Failed to select POI on min level because there are no levels")
        }
        
        selectPOI(atLevel: minLevel)
    }
    
    @IBAction func secondTouched() {
        guard let maxLevel = uniqueLevels.max() else {
            return debugPrint("Failed to select POI on max level because there are no levels")
        }
        
        selectPOI(atLevel: maxLevel)
    }
    
    private func selectPOI(atLevel level: Float) {
        
        guard let randomPOI = pois.filter({ LevelUtils.intersects($0.coordinate.levels, [level]) }).randomElement() else {
            return debugPrint("Failed to get random POI at level \(level)")
        }
        
        pointOfInterestManager.selectPOI(randomPOI)
    }
}
