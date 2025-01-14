//
//  POIsListViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 25/01/2024.
//  Copyright © 2024 Wemap SAS. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK

enum SortingType {
    case distance, time
}

final class POIsListViewController: UITableViewController {
    
    unowned var mapView: MapView!
    
    var userCoordinate: Coordinate!
    var sortingType = SortingType.distance
    
    private let disposeBag = DisposeBag()
    
    private lazy var poisWithInfo: [PointOfInterestWithInfo] = poiManager
        .getPOIs()
        .map { PointOfInterestWithInfo($0, nil) }
    
    private var poiManager: MapPointOfInterestManaging { mapView.pointOfInterestManager }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = nil
        
        let sort = if sortingType == .distance {
            poiManager.sortPOIsByGraphDistance(origin: userCoordinate)
        } else {
            poiManager.sortPOIsByDuration(origin: userCoordinate)
        }
        
        sort.asDriver(onErrorJustReturn: poisWithInfo)
            .startWith(poisWithInfo)
            .do(onNext: { [unowned self] in
                poisWithInfo = $0
            })
            .drive(tableView.rx.items) { tableView, _, poiWithInfo in
                let poi = poiWithInfo.poi
                let info = poiWithInfo.info
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
                cell.textLabel?.text = poi.name
                cell.detailTextLabel?.text = "id - \(poi.id)\nlevel - \(poi.coordinate.levels.first ?? -1)\naddress - \(poi.address)\n" +
                "distance - \(info?.distance ?? .greatestFiniteMagnitude)\nduration - \(info?.duration ?? .greatestFiniteMagnitude)"
                return cell
            }
            .disposed(by: disposeBag)
    }
    
    override func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        poiManager.selectPOI(poisWithInfo[indexPath.row].poi)
        dismiss(animated: true)
    }
}
