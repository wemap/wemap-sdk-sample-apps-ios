//
//  LevelSwitch.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 20/06/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import WemapCoreSDK
import WemapMapSDK

final class LevelSwitch: VerticalSegmentedControl {
    
    private var buildingManager: BuildingManager?
    
    // MARK: - Public methods
    
    func bind(buildingManager: BuildingManager) {
        unbind()
        self.buildingManager = buildingManager
        populateLevels(building: buildingManager.focusedBuilding)
        buildingManager.delegate = self
        delegate = self
    }
    
    func unbind() {
        buildingManager?.delegate = nil
        buildingManager = nil
        delegate = nil
    }
    
    // MARK: - Private methods
    
    private func populateLevels(building: Building?) {
        guard let building else {
            isHidden = true
            return
        }
        
        segmentTitles = building.levels.map(\.shortName)
        selectedIndex = building.activeLevelIndex
        isHidden = false
    }
}

// MARK: - BuildingManagerDelegate

extension LevelSwitch: BuildingManagerDelegate {
    
    func buildingManager(_: BuildingManager, didFocusBuilding building: Building?) {
        populateLevels(building: building)
    }
    
    func buildingManager(_: BuildingManager, didChangeLevel _: Level, ofBuilding building: Building) {
        selectedIndex = building.activeLevelIndex
    }
    
    func buildingManager(_: BuildingManager, didFailWithError error: any Error) {
        debugPrint("\(#function) with error \(error)")
    }
}

// MARK: - VerticalSegmentedControlDelegate

extension LevelSwitch: VerticalSegmentedControlDelegate {
    
    func verticalSegmentedControl(_: VerticalSegmentedControl, didSelectSegmentAt index: Int) {
        buildingManager?.focusedBuilding?.activeLevelIndex = index
    }
}
