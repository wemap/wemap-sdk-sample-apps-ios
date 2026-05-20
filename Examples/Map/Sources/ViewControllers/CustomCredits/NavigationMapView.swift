//
//  NavigationMapView.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 07/05/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import UIKit
import WemapMapSDK

final class NavigationMapView: MapView {

    override func showAttribution(_ sender: Any) {
        if let lp = sender as? UILongPressGestureRecognizer, lp.state != .began { return }
        var responder: UIResponder? = self
        while let r = responder {
            if let vc = r as? UIViewController {
                vc.present(CreditsViewController(), animated: true)
                return
            }
            responder = r.next
        }
    }
}
