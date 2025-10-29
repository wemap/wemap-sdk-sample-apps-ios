//
//  CameraViewController.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 04/09/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import ARKit
import RealityKit
import UIKit
import WemapMapSDK
import WemapPositioningSDKVPSARKit

class CameraViewController: UIViewController {

    var session: ARSession!
    var vpsLocationSource: VPSARKitLocationSource!
    var vpsDelegateDispatcher: VPSDelegateDispatcher!
    var locationManagerDelegateDispatcher: LocationManagerDelegateDispatcher!
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var startScanButton: UIButton!
    @IBOutlet var stopScanButton: UIButton!
    
    private var arView: ARView!
    private weak var currentToast: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.frame)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(arView, at: 0)
        arView.session = session
        
        locationManagerDelegateDispatcher.secondary = self
        vpsDelegateDispatcher.secondary = self
    }
    
    @IBAction func startScan() {
        vpsLocationSource.startScan()
    }
    
    @IBAction func stopScan() {
        vpsLocationSource.stopScan()
    }
    
    @IBAction func close() {
        dismiss(animated: true)
    }
    
    // FIXME: workaround to avoid automatic stopping of the session due to iOS 18 changes.
    // before if you set your custom session, you have to start and stop it manually.
    // Now even if it's a custom session - it will be automatically stopped when view is hidden.
    // And it's not even possible to set nil to reset the session. So here we set new session just to remove control from our own one.
    // ARSession does not report any changes in state or errors when it happens, that's why we consider this behaviour as a bug.
    // so you can't differentiate this behaviour is tracking lost or a bug. because last reported state is normal, but position is not updated
    override func viewWillDisappear(_ animated: Bool) {
        if #available(iOS 18.0, *) {
            arView.session = ARSession()
        }
        super.viewWillDisappear(animated)
    }
    
    private func showToast(message: String) {
        currentToast?.removeFromSuperview()
        currentToast = ToastHelper.showToast(message: message, onView: view)
    }
}

extension CameraViewController: VPSARKitLocationSourceDelegate {
    
    func locationSource(_: VPSARKitLocationSource, didChangeScanStatus status: VPSARKitLocationSource.ScanStatus) {
        debugPrint("VPS scan status changed - \(status)")
        
        if status.isStarted {
            infoLabel.text = "VPS scanning started"
            startScanButton.isEnabled = false
            stopScanButton.isEnabled = true
        } else {
            infoLabel.text = "VPS scanning stopped"
            startScanButton.isEnabled = true
            stopScanButton.isEnabled = false
            if vpsLocationSource.state.isAccurate {
                showToast(message: "Scanning is stopped and state is accurate, so you can close scanner.")
            }
        }
    }
    
    func locationSource(_: VPSARKitLocationSource, didChangeState state: VPSARKitLocationSource.State) {
        
        debugPrint("VPS state changed - \(state)")
        
        switch state {
        case .notPositioning:
            showToast(message: "State is not positioning. Scan your environment")
        case let .degradedPositioning(reason):
            showToast(message: "State is degraded because \(reason). Scan your environment a bit more.")
        default: // .accuratePositioning
            showToast(message: "State is accurate and you can close scanner.")
        }
    }
}

extension CameraViewController: UserLocationManagerDelegate {
    
    func locationManager(_: UserLocationManager, didFailWithError error: any Error) {
        showToast(message: "Location Source failed with error - \(error)")
    }
}
