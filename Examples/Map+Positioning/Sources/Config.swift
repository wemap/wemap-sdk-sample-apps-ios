//
//  Config.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import WemapMapSDK
import WemapPositioningSDK
import WemapPositioningSDKVPSARKit

enum PreferencesKey: String {
    case mapVersion,
         positioningVersion,
         mapLibreVersion,
         cameraImageMaxSizeSmallerSide,
         staticPositionDetectorWindowDurationSeconds,
         staticPositionDetectorGeofenceRadiusMeters,
         conveyingDetectorDurationSeconds,
         conveyingDetectorElevatorBufferWidth,
         conveyingDetectorLinearConveyingBuffersWidth
}

func customKeysAndValues() -> [String: Any] {
    
    VPSARKitConstants.cameraImageMaxSizeSmallerSide = UserDefaults
        .double(forKey: .cameraImageMaxSizeSmallerSide, defaultValue: VPSARKitConstants.cameraImageMaxSizeSmallerSide)
    
    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version,
        .positioningVersion: Bundle.positioning.version
    ]
    
    VPSARKitConstants.StaticPositionDetector.windowDurationSeconds = UserDefaults.double(
        forKey: .staticPositionDetectorWindowDurationSeconds,
        defaultValue: VPSARKitConstants.StaticPositionDetector.windowDurationSeconds
    )
    
    VPSARKitConstants.StaticPositionDetector.geofenceRadiusMeters = UserDefaults.float(
        forKey: .staticPositionDetectorGeofenceRadiusMeters,
        defaultValue: VPSARKitConstants.StaticPositionDetector.geofenceRadiusMeters
    )
    
    VPSARKitConstants.ConveyingDetector.durationSeconds = UserDefaults.int(
        forKey: .conveyingDetectorDurationSeconds,
        defaultValue: VPSARKitConstants.ConveyingDetector.durationSeconds
    )
    
    VPSARKitConstants.ConveyingDetector.elevatorBufferWidth = UserDefaults.double(
        forKey: .conveyingDetectorElevatorBufferWidth,
        defaultValue: VPSARKitConstants.ConveyingDetector.elevatorBufferWidth
    )
    
    VPSARKitConstants.ConveyingDetector.linearConveyingBuffersWidth = UserDefaults.double(
        forKey: .conveyingDetectorLinearConveyingBuffersWidth,
        defaultValue: VPSARKitConstants.ConveyingDetector.linearConveyingBuffersWidth
    )
    
    let dict = Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
    return dict
}
