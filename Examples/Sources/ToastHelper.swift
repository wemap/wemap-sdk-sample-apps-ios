//
//  ToastHelper.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 12/10/2022.
//  Copyright © 2022 Wemap SAS. All rights reserved.
//

import UIKit

class ToastHelper {
    
    @discardableResult
    static func showToast(message: String, onView view: UIView, hideDelay: TimeInterval = 2, completion: (() -> Void)? = nil) -> UILabel {
        
        let toastLabel = UILabel(frame: .zero)
        
        toastLabel.backgroundColor = .black.withAlphaComponent(0.6)
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 12)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            toastLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -(view.safeAreaInsets.left + view.safeAreaInsets.right + 60))
        ])
        
        UIView.animate(withDuration: 1, delay: hideDelay, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
            completion?()
        })
        
        toastLabel.layoutIfNeeded()
        
        return toastLabel
    }
}
