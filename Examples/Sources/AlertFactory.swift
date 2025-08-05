//
//  AlertFactory.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 23/06/2025.
//  Copyright © 2025 Wemap SAS. All rights reserved.
//

import RxSwift

enum AlertFactory {
    
    static func presentSimpleAlert(
        on vc: UIViewController, message: String, errorMessage: String, positiveText: String = "Ok", negativeText: String = "Cancel"
    ) -> Single<Void> {
        .create(subscribe: { observer in
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: positiveText, style: .default) { _ in
                observer(.success(()))
            }
            let cancelAction = UIAlertAction(title: negativeText, style: .cancel) { _ in
                observer(.failure(NSError(domain: errorMessage, code: 0)))
            }
            for action in [okAction, cancelAction] {
                alert.addAction(action)
            }
            vc.present(alert, animated: true)
            return Disposables.create { [weak alert] in
                alert?.dismiss(animated: true)
            }
        })
    }
}
