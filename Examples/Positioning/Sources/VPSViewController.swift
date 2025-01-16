//
//  VPSViewController.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 15/09/2022.
//  Copyright © 2022 Wemap SAS. All rights reserved.
//

import RealityKit
import UIKit
import WemapCoreSDK
import WemapPositioningSDKVPSARKit

@available(iOS 13.0, *)
final class VPSViewController: UIViewController {
    
    var mapData: MapData?
    
    @IBOutlet var mapPlaceholder: UIView!
    @IBOutlet var rescanButton: UIButton!
    
    @IBOutlet var debugTextState: UILabel!
    @IBOutlet var debugTextScanStatus: UILabel!
    @IBOutlet var debugTextCoordinate: UILabel!
    @IBOutlet var debugTextAttitude: UILabel!
    @IBOutlet var debugTextHeading: UILabel!
    
    @IBOutlet var scanButtons: UIStackView!
    @IBOutlet var startScanButton: UIButton!
    @IBOutlet var stopScanButton: UIButton!
    
    private var arView: ARView!
    private var vpsLocationSource: VPSARKitLocationSource!
    
    private weak var currentToast: UIView?
    private var rescanRequested = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.frame)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(arView, at: 0)
        
        setupLocationSource()
        
        arView.session = vpsLocationSource.session
    }
    
    private func setupLocationSource () {
        vpsLocationSource = VPSARKitLocationSource(serviceURL: mapData?.extras?.vpsEndpoint ?? Constants.vpsEndpoint)
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
    
    private func showMapPlaceholder() {
        mapPlaceholder.isHidden = false
        scanButtons.isHidden = true
    }
    
    private func showCamera() {
        mapPlaceholder.isHidden = true
        scanButtons.isHidden = false
    }
    
    private func updateScanButtons(status: VPSARKitLocationSource.ScanStatus) {
        let isScanning = status == .started
        startScanButton.isEnabled = !isScanning
        stopScanButton.isEnabled = isScanning
    }
    
    private func showError(message: String) {
        currentToast?.removeFromSuperview()
        currentToast = ToastHelper.showToast(message: message, onView: view)
    }
    
    deinit {
        vpsLocationSource.stop()
    }
}

// MARK: Delegates

@available(iOS 13.0, *)
extension VPSViewController: LocationSourceDelegate {
    
    func locationSource(_ locationSource: any LocationSource, didUpdateCoordinate coordinate: Coordinate) {
        DispatchQueue.main.async { [self] in
            debugTextCoordinate.text = String(format: "lat: %.5f, lng: %.5f, lvl: \(coordinate.levels)", coordinate.latitude, coordinate.longitude)
        }
    }
    
    func locationSource(_ locationSource: any LocationSource, didUpdateAttitude attitude: Attitude) {
        DispatchQueue.main.async { [self] in
            let q = attitude.quaternion.vector
            debugTextAttitude.text = String(format: "w: %.2f, x: %.2f, y: %.2f, z: %.2f", q.w, q.x, q.y, q.z)
            debugTextHeading.text = String(format: "%.2f", attitude.headingDegrees)
        }
    }
    
    func locationSource(_ locationSource: any LocationSource, didFailWithError error: any Error) {
        DispatchQueue.main.async { [self] in
            showError(message: "LS: \(error)")
        }
    }
}

@available(iOS 13.0, *)
extension VPSViewController: VPSARKitLocationSourceDelegate {
    
    func locationSource(_ locationSource: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
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
    
    func locationSource(_ locationSource: VPSARKitLocationSource, didChangeScanStatus status: VPSARKitLocationSource.ScanStatus) {
        debugTextScanStatus.text = "\(status)"
        updateScanButtons(status: status)
        
        // rescan successful, reset rescanRequested and update UI
        if status == .stopped && vpsLocationSource.state == .accuratePositioning {
            rescanRequested = false
            showMapPlaceholder()
        }
    }
    
    func locationSource(_ locationSource: VPSARKitLocationSource, didFailWithError error: VPSARKitLocationSourceError) {
        showError(message: error.description)
    }
}
