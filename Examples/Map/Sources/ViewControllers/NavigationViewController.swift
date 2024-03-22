//
//  NavigationViewController.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import MapLibre
import RxSwift
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class NavigationViewController: MapViewController {
    
    typealias Delay = UIConstants.Delay
    typealias Inset = UIConstants.Inset
    
    @IBOutlet var startNavigationButton: UIButton!
    @IBOutlet var stopNavigationButton: UIButton!
    @IBOutlet var startNavigationFromUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var removeUserCreatedAnnotationsButton: UIButton!
    @IBOutlet var navigationInfo: UILabel!
    
    private var userCreatedAnnotations: [MLNAnnotation] {
        map.annotations?
            .filter { $0.title == "user-created" } ?? []
    }
    
    private var simulator: SimulatorLocationSource? {
        map.userLocationManager.locationSource as? SimulatorLocationSource
    }
    
    private var navigationManager: NavigationManager { map.navigationManager }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationManager.delegate = self
        pointOfInterestManager.delegate = self
        
        createLongPressGestureRecognizer()
        
        map.userTrackingMode = .followWithHeading
        
        // this way you can specify user location indicator appearance
    
//        let foreground = UIImage(named: "UserPuckIcon")
//        let heading = UIImage(named: "UserArrow")
        
        map.userLocationManager.userLocationViewStyle = .init(
//            foregroundImage: foreground,
//            backgroundImage: UIImage(named: "UserIcon"),
//            headingImage: heading,
            foregroundTintColor: .systemPink,
            backgroundTintColor: .black,
            headingTintColor: .green,
            outOfActiveLevelStyle: .init(
//                foregroundImage: foreground,
//                headingImage: heading,
                foregroundTintColor: .darkGray,
                headingTintColor: .red,
                alpha: 0.5
            )
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        ToastHelper.showToast(
            message: "Create 1 or 2 annotations by long press on the map to be able to start navigation. " +
                "1 annotation to start from user location. 2 annotations to start from custom location",
            onView: view, hideDelay: Delay.short
        )
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    private func createLongPressGestureRecognizer() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        map.addGestureRecognizer(longPress)
    }
    
    @objc private func longPressGesture(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        guard userCreatedAnnotations.count < 2 else {
            ToastHelper.showToast(message: "You already created 2 annotations. Remove old ones to be able to add new", onView: view)
            return
        }
        let coord = map.convert(gesture.location(in: map), toCoordinateFrom: map)
        let point = MLNPointAnnotation()
        point.coordinate = coord
        point.title = "user-created"
        point.subtitle = getCurrentLevel(for: coord)
        map.addAnnotation(point)
        
        map.setCenter(coord, zoomLevel: 18, edgePadding: .init(top: 0, left: 0, bottom: 200, right: 0))
        
        updateUI()
    }
    
    private func getCurrentLevel(for coordinate: CLLocationCoordinate2D) -> String {
        guard let building = focusedBuilding else {
            debugPrint("Failed to retrieve focused building. Considering this annotation as outdoor")
            return String()
        }
        
        return building.boundingBox.contains(coordinate) ? String(building.activeLevel.id) : String()
    }
    
    @IBAction func startNavigationFromUserLocation() {
        let to = userCreatedAnnotations.first!
        let destination = Coordinate(coordinate2D: to.coordinate, level: Float(to.subtitle!!)!)
        
        startNavigation(origin: nil, destination: destination)
    }
    
    @IBAction func stopNavigation() {
        let result = navigationManager.stopNavigation()
        switch result {
        case .success:
            simulator?.reset()
            stopNavigationButton.isEnabled = false
            updateUI()
        case let .failure(error):
            ToastHelper.showToast(message: "Failed to stop navigation with error - \(error)", onView: view, hideDelay: Delay.long)
        }
    }
    
    @IBAction func startNavigationFromUserCreatedAnnotations() {
        
        let from = userCreatedAnnotations[0]
        let to = userCreatedAnnotations[1]
        
        let fromLevels = getLevelFromAnnotation(from)
        let toLevels = getLevelFromAnnotation(to)
        
        let origin, destination: Coordinate
        if locationSourceType != .polestarEmulator {
            origin = .init(coordinate2D: from.coordinate, levels: fromLevels)
            destination = .init(coordinate2D: to.coordinate, levels: toLevels)
        } else {
            // for testing you can comment out and uncomment placemarks in nao.kml file and corresponding origin/destination below
            // Default path
//            origin = .init(coordinate2D: .init(latitude: 48.84487592, longitude: 2.37362684), level: -1)
//            destination = .init(coordinate2D: .init(latitude: 48.84428454, longitude: 2.37390447), level: 0)
            
            // Path at less than 3 meters from network
            origin = .init(coordinate2D: .init(latitude: 48.84458308799957, longitude: 2.3731548097070134), level: 0)
            destination = .init(coordinate2D: .init(latitude: 48.84511200990592, longitude: 2.3738383127780676), level: 0)
            
            // Path at less than 3 meters from network and route recalculation
//            origin = .init(coordinate2D: .init(latitude: 48.84458308799957, longitude: 2.3731548097070134), level: 0)
//            destination = .init(coordinate2D: .init(latitude: 48.84511200990592, longitude: 2.3738383127780676), level: 0)

            // Path from level -1 to 0 and route recalculation
//            origin = .init(coordinate2D: .init(latitude: 48.84445563, longitude: 2.37319782), level: -1)
//            destination = .init(coordinate2D: .init(latitude: 48.84502948, longitude: 2.37451864), level: 0)

            // Path indoor to outdoor
//            origin = .init(coordinate2D: .init(latitude: 48.84482873, longitude: 2.37378956), level: 0)
//            destination = .init(coordinate2D: .init(latitude: 48.8455159, longitude: 2.37305333))
        }
        
        startNavigation(origin: origin, destination: destination)
    }
    
    @IBAction func removeUserCreatedAnnotations() {
        map.removeAnnotations(userCreatedAnnotations)
        updateUI()
    }
    
    private func startNavigation(origin: Coordinate?, destination: Coordinate) {
        disableStartButtons()
        
        navigationManager
            .startNavigation(origin: origin, destination: destination, options: globalNavigationOptions /* , searchOptions: .init(avoidStairs: true) */ )
            .subscribe(
                onSuccess: { [unowned self] itinerary in
                    simulator?.setItinerary(itinerary)
                    stopNavigationButton.isEnabled = true
                },
                onFailure: { [unowned self] error in
                    stopNavigationButton.isEnabled = false
                    updateUI()
                    ToastHelper.showToast(
                        message: "Failed to start navigation from user position to - \(destination) with error - \(error)",
                        onView: view, hideDelay: Delay.long
                    )
                }
            ).disposed(by: disposeBag)
    }
    
    private func updateUI() {
        startNavigationButton.isEnabled = userCreatedAnnotations.count == 1 && !stopNavigationButton.isEnabled
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = userCreatedAnnotations.count == 2 && !stopNavigationButton.isEnabled
        removeUserCreatedAnnotationsButton.isEnabled = !userCreatedAnnotations.isEmpty
    }
    
    private func disableStartButtons() {
        startNavigationButton.isEnabled = false
        startNavigationFromUserCreatedAnnotationsButton.isEnabled = false
    }
    
    private func getLevelFromAnnotation(_ annotation: MLNAnnotation) -> [Float] {
        guard let subtitle = annotation.subtitle! else {
            return []
        }
        return subtitle.isEmpty ? [] : [Float(subtitle)!]
    }
}

extension NavigationViewController: PointOfInterestManagerDelegate {
    
    func pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest) {
        ToastHelper.showToast(message: "POI clicked with id - \(poi.id)", onView: view, hideDelay: Delay.short) {
            self.pointOfInterestManager.unselectPOI(poi)
        }
    }
}

extension NavigationViewController: NavigationManagerDelegate {
    
    func navigationManager(_: NavigationManager, didUpdateNavigationInfo info: NavigationInfo) {
        navigationInfo.isHidden = false
        let nextStep = info.nextStep?.getNavigationInstructions().instructions ?? "no"
        navigationInfo.text = info.shortDescription + "\nNext - \(nextStep)"
    }
    
    func navigationManager(_: NavigationManager, didStartNavigation itinerary: Itinerary) {
        navigationInfo.isHidden = false
        ToastHelper.showToast(message: "Navigation started", onView: view)
        stopNavigationButton.isEnabled = true
        
        for leg in itinerary.legs.flatMap(\.steps) {
            let instructions = leg.getNavigationInstructions()
            debugPrint(instructions)
        }
    }
    
    func navigationManager(_: NavigationManager, didStopNavigation _: Itinerary) {
        navigationInfo.isHidden = true
        ToastHelper.showToast(message: "Navigation stopped", onView: view, hideDelay: Delay.short)
        stopNavigationButton.isEnabled = false
    }
    
    func navigationManager(_: NavigationManager, didArriveAtDestination _: Itinerary) {
        ToastHelper.showToast(message: "Navigation manager didArriveAtDestination", onView: view, hideDelay: Delay.short, bottomInset: Inset.mid)
    }
    
    func navigationManager(_: NavigationManager, didFailWithError error: NavigationError) {
        ToastHelper.showToast(message: "Navigation failed with error - \(error)", onView: view, hideDelay: Delay.short)
    }
    
    func navigationManager(_: NavigationManager, didRecalculateItinerary itinerary: Itinerary) {
        ToastHelper.showToast(message: "Navigation itinerary recalculated - \(itinerary)", onView: view, hideDelay: Delay.short)
    }
}
