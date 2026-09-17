//
//  SceneDelegate.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 16/09/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import UIKit

/**
 Builds the window of every example app.

 Apps built with the iOS 27 SDK must adopt the UIScene life cycle - UIKit refuses to launch them otherwise -
 so the window is created here instead of in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`.
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        window.makeKeyAndVisible()
        
        self.window = window
    }
}
