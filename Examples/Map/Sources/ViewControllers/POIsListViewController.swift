//
//  POIsListViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 25/01/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import Combine
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

    private var cancellable: AnyCancellable?

    private lazy var poisWithInfo: [PointOfInterestWithInfo] = poiManager
        .getPOIs()
        .map { .init(poi: $0, info: nil) }

    private lazy var dataSource = UITableViewDiffableDataSource<Section, PointOfInterestWithInfo>(
        tableView: tableView
    ) { tableView, indexPath, poiWithInfo in
        let poi = poiWithInfo.poi
        let info = poiWithInfo.info
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = poi.name
        cell.detailTextLabel?.text = "id - \(poi.id)\nlevel - \(poi.coordinate.levels.first ?? -1)\naddress - \(poi.address ?? "missing")\n"
            + "distance - \(info?.distance ?? .greatestFiniteMagnitude)\nduration - \(info?.duration ?? .greatestFiniteMagnitude)"
        return cell
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = nil
        
        let sort = if sortingType == .distance {
            poiManager.sortPOIsByGraphDistance(origin: userCoordinate)
        } else {
            poiManager.sortPOIsByDuration(origin: userCoordinate)
        }
        
        cancellable = sort
            .replaceError(with: poisWithInfo)
            .prepend(poisWithInfo)
            .handleEvents(receiveOutput: { [unowned self] in
                poisWithInfo = $0
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                var snapshot = NSDiffableDataSourceSnapshot<Section, PointOfInterestWithInfo>()
                snapshot.appendSections([.main])
                snapshot.appendItems(items)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
            }
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        poiManager.selectPOI(poisWithInfo[indexPath.row].poi)
        dismiss(animated: true)
    }
}
