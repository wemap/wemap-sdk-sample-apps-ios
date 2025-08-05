//
//  VPSViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 15/09/2022.
//  Copyright © 2022 Wemap SAS. All rights reserved.
//

import RealityKit
import RxSwift
import UIKit
import WemapCoreSDK
import WemapPositioningSDKVPSARKit

@available(iOS 13.0, *)
final class VPSViewController: UIViewController {
    
    var mapData: MapData!
    
    @IBOutlet var mapPlaceholder: UIView!
    
    @IBOutlet var debugTextState: UILabel!
    @IBOutlet var debugTextScanStatus: UILabel!
    @IBOutlet var debugTextCoordinate: UILabel!
    @IBOutlet var debugTextAttitude: UILabel!
    @IBOutlet var debugTextHeading: UILabel!
    
    @IBOutlet var scanButtons: UIStackView!
    @IBOutlet var startScanButton: UIButton!
    @IBOutlet var stopScanButton: UIButton!
    
    @IBOutlet var itinerarySourceLabel: UILabel!
    @IBOutlet var itinerarySourceSwitch: UISwitch!
    
    private var arView: ARView!
    private var vpsLocationSource: VPSARKitLocationSource!
    
    private weak var currentToast: UIView?
    private var rescanRequested = false
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.frame)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(arView, at: 0)
        
        setupLocationSource()
        
        // workaround needed to avoid automatic stopping of the session due to iOS 18 changes when using ARView
        // in this particular example it's not necessary because we keep ARView running, but if you present it and dismiss you have to override session onDismiss
        // Explanation:
        // before if you set your custom session, you have to start and stop it manually.
        // Now even if it's a custom session - it will be automatically stopped when view is hidden.
        // And it's not even possible to set nil to reset the session. So here we set new session just to remove control from our own one.
        // ARSession does not report any changes in state or errors when it happens, that's why we consider this behaviour as a bug.
        // so you can't differentiate this behaviour is tracking lost or a bug. because last reported state is normal, but position is not updated
        // https://github.com/wemap/wemap-sdk-sample-apps-ios/blob/99dcdd56230782b7c87e290fc38dba4eecabe300/Examples/Map%2BPositioning/Sources/ViewControllers/CameraViewController.swift#L73-L85
        arView.session = vpsLocationSource.session
    }
    
    private func setupLocationSource() {
        vpsLocationSource = VPSARKitLocationSource(mapData: mapData)
        vpsLocationSource.delegate = self
        vpsLocationSource.vpsDelegate = self
        
        vpsLocationSource.start()
        
        debugTextState.text = "\(vpsLocationSource.state)"
        debugTextScanStatus.text = "\(vpsLocationSource.scanStatus)"
    }
    
    // MARK: UI
    
    @IBAction func startScan() {
        vpsLocationSource.startScan()
    }
    
    @IBAction func stopScan() {
        vpsLocationSource.stopScan()
    }
    
    @IBAction func rescan() {
        rescanRequested = true
        showCamera()
    }
    
    @IBAction func itinerarySourceSwitchValueChanged() {
        itinerarySourceLabel.text = itinerarySourceSwitch.isOn ? "Use manually created Itinerary" : "Use Itinerary provided by Wemap API"
    }
    
    /**
     - Warning: This method is temporary and may be removed in any future release.
     */
    @IBAction func forceUserPositionButtonTouched() {
        // Let consider levels mapping (level 0 => 0m, -1 => level -3.5m, level -2 => -7m) // From Wemap BO
        // We want to set position to the end of escalators at level -1
        let locationAfterEscalators = Coordinate(latitude: 48.88018539374073, longitude: 2.3567438682277952, altitude: -3.5)
        let locationUpdated = vpsLocationSource.forceUpdatePosition(coordinate: locationAfterEscalators)
        if !locationUpdated {
            Logger.e("Failed to force user position.")
        }
    }
    
    /**
     Once you start receiving updated `Coordinate`s, you can assign an itinerary to the `VPSARKitLocationSource`.
     
     Assigning an itinerary to `VPSARKitLocationSource` when a user is following an A→B itinerary enhances the overall navigation experience (e.g., itinerary projections, conveyor detection, etc.).
     
     For example, when conveying is detected, the system will prompt you to rescan the environment to restore tracking.
     */
    private func showMapPlaceholder() {
        mapPlaceholder.isHidden = false
        scanButtons.isHidden = true
        if itinerarySourceSwitch.isOn {
            vpsLocationSource.itinerary = hardcodedItinerary() // ItineraryLoader.loadFromGeoJSON()
        } else {
            calculateItinerary()
        }
    }
    
    private func showCamera() {
        mapPlaceholder.isHidden = true
        scanButtons.isHidden = false
    }
    
    private func updateScanButtons(status: VPSARKitLocationSource.ScanStatus) {
        let isScanning = status.isStarted
        startScanButton.isEnabled = !isScanning
        stopScanButton.isEnabled = isScanning
    }
    
    private func showError(message: String) {
        currentToast?.removeFromSuperview()
        currentToast = ToastHelper.showToast(message: message, onView: view)
    }
    
    private func calculateItinerary() {
        
        let origin = Coordinate(latitude: 48.88007462, longitude: 2.35591097, level: 0)
        let destination = Coordinate(latitude: 48.88141308, longitude: 2.35747255, level: -2)
        
        ServiceFactory
            .getItineraryProvider()
            .itineraries(origin: origin, destination: destination, mapId: mapData!.id)
            .subscribe(onSuccess: { itineraries in
                self.vpsLocationSource.itinerary = itineraries.first
            }, onFailure: { error in
                debugPrint("Failed to calculate itineraries with error: \(error)")
            })
            .disposed(by: disposeBag)
    }
    
    private func hardcodedItinerary() -> Itinerary {
        
        let origin = Coordinate(latitude: 48.88007462, longitude: 2.35591097, level: 0)
        let destination = Coordinate(latitude: 48.88141308, longitude: 2.35747255, level: -2)
        
        let coordinatesLevel0 = [
            [2.3559003, 48.88005135],
            [2.35613366, 48.88000508],
            [2.35623278, 48.87998696],
            [2.35636233, 48.87996258],
            [2.3564454, 48.88014336],
            [2.35657153, 48.88013655]
        ].map { Coordinate(latitude: $0[1], longitude: $0[0], level: 0) }
        
        let legSegmentsLevel0 = LegSegment.fromCoordinates(coordinatesLevel0)
        
        let coordinatesFrom0ToMinus1 = [
            [2.35657153, 48.88013655],
            [2.3567008, 48.8801748]
        ].map { Coordinate(latitude: $0[1], longitude: $0[0], levels: [-1, 0]) }
        
        let levelChangeFrom0ToMinus1 = LevelChange(difference: -1, direction: .down, type: .escalator)
        let legSegmentsFrom0ToMinus1 = LegSegment.fromCoordinates(coordinatesFrom0ToMinus1, levelChange: levelChangeFrom0ToMinus1)
        
        let coordinatesLevelMinus1 = [
            [2.3567008, 48.8801748],
            [2.35672744, 48.88017653],
            [2.35684126, 48.88020268],
            [2.35688225, 48.88028507],
            [2.35702803, 48.88032342],
            [2.35714357, 48.88055641],
            [2.35716058, 48.88058641],
            [2.35719467, 48.8805796],
            [2.35723088, 48.88057183],
            [2.357253, 48.88061996]
        ].map { Coordinate(latitude: $0[1], longitude: $0[0], level: -1) }
        
        let legSegmentsLevelMinus1 = LegSegment.fromCoordinates(coordinatesLevelMinus1)
        
        let coordinatesFromMinus1ToMinus2 = [
            [2.357253, 48.88061996],
            [2.35727559, 48.88066565]
        ].map { Coordinate(latitude: $0[1], longitude: $0[0], levels: [-2, -1]) }
        
        let levelChangeFromMinus1ToMinus2 = LevelChange(difference: -1, direction: .down, type: .escalator)
        let legSegmentsFromMinus1ToMinus2 = LegSegment.fromCoordinates(coordinatesFromMinus1ToMinus2, levelChange: levelChangeFromMinus1ToMinus2)
        
        let coordinatesLevelMinus2 = [
            [2.35727559, 48.88066565],
            [2.35731332, 48.88074658],
            [2.35728039, 48.88075276],
            [2.35723537, 48.88076096],
            [2.35731739, 48.88094625],
            [2.35738281, 48.88110437],
            [2.35745716, 48.88126764],
            [2.35749811, 48.88135969],
            [2.35752604, 48.88142664],
            [2.35748253, 48.88143515]
        ].map { Coordinate(latitude: $0[1], longitude: $0[0], level: -2) }
        
        let legSegmentsLevelMinus2 = LegSegment.fromCoordinates(coordinatesLevelMinus2)
        
        let segments = legSegmentsLevel0 + legSegmentsFrom0ToMinus1 + legSegmentsLevelMinus1 + legSegmentsFromMinus1ToMinus2 + legSegmentsLevelMinus2
        return .init(origin: origin, destination: destination, segments: segments)
    }
    
    deinit {
        vpsLocationSource.stop()
    }
}

// MARK: Delegates

@available(iOS 13.0, *)
extension VPSViewController: LocationSourceDelegate {
    
    func locationSource(_: any LocationSource, didUpdateCoordinate coordinate: Coordinate) {
        DispatchQueue.main.async { [self] in
            debugTextCoordinate.text = String(format: "lat: %.6f, lng: %.6f, lvl: \(coordinate.levels)", coordinate.latitude, coordinate.longitude)
        }
    }
    
    func locationSource(_: any LocationSource, didUpdateAttitude attitude: Attitude) {
        DispatchQueue.main.async { [self] in
            let q = attitude.quaternion.vector
            debugTextAttitude.text = String(format: "w: %.2f, x: %.2f, y: %.2f, z: %.2f", q.w, q.x, q.y, q.z)
            debugTextHeading.text = String(format: "%.2f", attitude.headingDegrees)
        }
    }
    
    func locationSource(_: any LocationSource, didFailWithError error: any Error) {
        DispatchQueue.main.async { [self] in
            showError(message: "LS: \(error)")
        }
    }
}

@available(iOS 13.0, *)
extension VPSViewController: VPSARKitLocationSourceDelegate {
    
    func locationSource(_: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
        debugTextState.text = "\(state)"
        
        // if rescan requested - don't update UI on state changes. UI will be updated on scan status change
        guard !rescanRequested else {
            return
        }
        
        switch state {
        case .accuratePositioning, .degradedPositioning:
            showMapPlaceholder()
        case .notPositioning:
            showCamera()
        }
    }
    
    func locationSource(_: VPSARKitLocationSource, didChangeScanStatus status: VPSARKitLocationSource.ScanStatus) {
        debugTextScanStatus.text = "\(status)"
        updateScanButtons(status: status)
        
        // rescan successful, reset rescanRequested and update UI
        if status == .stopped, vpsLocationSource.state.isAccurate {
            rescanRequested = false
            showMapPlaceholder()
        }
    }
}
