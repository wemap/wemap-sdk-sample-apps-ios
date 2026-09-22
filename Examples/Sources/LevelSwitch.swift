//
//  LevelSwitch.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 20/06/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import WemapMapSDK

/**
 The samples' own levels rail, bound to a `BuildingManager`.

 No sorting here on purpose: `BuildingData` sorts a building's levels ascending at decode, and
 `VerticalSegmentedControl` draws them bottom-up, so the rail already reads highest first.
 */
final class LevelSwitch: VerticalSegmentedControl {

    private weak var buildingManager: BuildingManager?
    private var observationTasks: [Task<Void, Never>] = []

    isolated deinit {
        unbind()
    }

    // MARK: - Public methods

    func bind(buildingManager: BuildingManager) {
        unbind()
        self.buildingManager = buildingManager
        populateLevels(building: buildingManager.focusedBuilding)
        delegate = self
        observe(buildingManager)
    }

    func unbind() {
        for task in observationTasks {
            task.cancel()
        }
        observationTasks.removeAll()
        buildingManager = nil
        delegate = nil
    }

    // MARK: - Private methods

    private func observe(_ buildingManager: BuildingManager) {
        let focusedBuildings = buildingManager.focusedBuildings
        let activeLevelChanges = buildingManager.activeLevelChanges
        let errors = buildingManager.errors

        observationTasks = [
            Task { [weak self] in
                for await building in focusedBuildings {
                    guard let self else {
                        return
                    }
                    populateLevels(building: building)
                }
            },
            Task { [weak self] in
                for await (building, _) in activeLevelChanges {
                    guard let self else {
                        return
                    }
                    selectedIndex = building.activeLevelIndex
                }
            },
            Task {
                for await error in errors {
                    print("building manager failed with error \(error)")
                }
            }
        ]
    }

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

// MARK: - VerticalSegmentedControlDelegate

extension LevelSwitch: @MainActor VerticalSegmentedControlDelegate {

    func verticalSegmentedControl(_: VerticalSegmentedControl, didSelectSegmentAt index: Int) {
        buildingManager?.focusedBuilding?.activeLevelIndex = index
    }
}
