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
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        SettingsBundleHelper.applySettings(customKeysAndValues: customKeysAndValues())
        
        return true
    }
}
