//
//  AppDelegate.swift
//  Examples
//
//  Created by Evgenii Khrushchev on 15/09/2022.
//  Copyright © 2022 Wemap SAS. All rights reserved.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        SettingsBundleHelper.applySettings(customKeysAndValues: customKeysAndValues())
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        window?.makeKeyAndVisible()
        
        return true
    }
}
