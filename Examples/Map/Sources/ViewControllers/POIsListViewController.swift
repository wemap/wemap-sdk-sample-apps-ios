//
//  POIsListViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 25/01/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import UIKit
import WemapCoreSDK
import WemapMapSDK

enum SortingType {
    case distance, time
}

enum Section {
    case main
}

final class POIsListViewController: UITableViewController {

    unowned var poiManager: MapPointOfInterestManaging!

    var userCoordinate: Coordinate!
    var sortingType = SortingType.distance

    private lazy var poisWithInfo: [PointOfInterestWithItineraryInfo] = poiManager
        .getAllPOIs()
        .map { .init(pointOfInterest: $0, itineraryInfo: nil) }

    private lazy var dataSource = UITableViewDiffableDataSource<Section, PointOfInterestWithItineraryInfo>(
        tableView: tableView
    ) { tableView, indexPath, poiWithInfo in
        let poi = poiWithInfo.pointOfInterest
        let info = poiWithInfo.itineraryInfo
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = poi.name
        cell.detailTextLabel?.text = "id - \(poi.id)\nlevel - \(poi.coordinate.levels)\naddress - \(poi.address ?? "missing")\n"
            + "distance - \(info?.distance ?? .greatestFiniteMagnitude)\nduration - \(info?.duration ?? .greatestFiniteMagnitude)"
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = nil
        applySnapshot(poisWithInfo)

        Task {
            do {
                let sorted = if sortingType == .distance {
                    try await poiManager.sortPOIsByGraphDistance(origin: userCoordinate)
                } else {
                    try await poiManager.sortPOIsByDuration(origin: userCoordinate)
                }
                poisWithInfo = sorted
                applySnapshot(sorted)
            } catch {
                applySnapshot(poisWithInfo)
            }
        }
    }

    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        poiManager.selectPOI(poisWithInfo[indexPath.row].pointOfInterest)
        dismiss(animated: true)
    }

    // MARK: - Private

    private func applySnapshot(_ items: [PointOfInterestWithItineraryInfo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, PointOfInterestWithItineraryInfo>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
