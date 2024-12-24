//
//  CameraViewController.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 04/09/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import ARKit
import RealityKit
import RxSwift
import UIKit
import WemapPositioningSDKVPSARKit

@available(iOS 13.0, *)
class CameraViewController: UIViewController {

    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var startScanButton: UIButton!
    @IBOutlet var stopScanButton: UIButton!
    
    var session: ARSession!
    var vpsLocationSource: VPSARKitLocationSource!
    
    private let stateListener = SerialDisposable()
    private let disposeBag = DisposeBag()
    private var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arView = ARView(frame: view.frame)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(arView, at: 0)
        arView.session = session
        
        weak var previousToast: UIView?
        vpsLocationSource
            .rx.didFail
            .emit(onNext: { [unowned self] in
                previousToast?.removeFromSuperview()
                previousToast = ToastHelper.showToast(message: "VPS failed with error - \($0)", onView: view)
            })
            .disposed(by: disposeBag)
        
        vpsLocationSource
            .rx.didChangeScanStatus
            .emit(onNext: { [unowned self] in
                if $0 == .started {
                    infoLabel.text = "VPS scanning started"
                    startScanButton.isEnabled = false
                    stopScanButton.isEnabled = true
                } else {
                    infoLabel.text = "VPS scanning stopped"
                    startScanButton.isEnabled = true
                    stopScanButton.isEnabled = false
                }
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func startScan() {
        vpsLocationSource.startScan()
        stateListener.disposable = vpsLocationSource
            .rx.didChangeState.asObservable()
            .filter { $0 == .accuratePositioning }
            .take(1).asSingle()
            .subscribe(onSuccess: { [unowned self] _ in
                dismiss(animated: true)
            })
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

    // end
    
    @IBAction func stopScan() {
        vpsLocationSource.stopScan()
    }
    
    deinit {
        stateListener.dispose()
    }
}
