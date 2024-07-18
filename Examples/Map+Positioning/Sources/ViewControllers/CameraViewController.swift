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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let arView = ARView(frame: view.frame)
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
            .filter { $0 == .normal }
            .take(1).asSingle()
            .subscribe(onSuccess: { [unowned self] _ in
                dismiss(animated: true)
            })
    }
    
    @IBAction func stopScan() {
        vpsLocationSource.stopScan()
    }
    
    deinit {
        stateListener.dispose()
    }
}
