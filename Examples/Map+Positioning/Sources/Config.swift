//
//  Config.swift
//  Map+PositioningExample
//
//  Created by Evgenii Khrushchev on 24/01/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import Foundation
import WemapCoreSDK
import WemapMapSDK
import WemapPositioningSDKVPSARKit

enum PreferencesKey: String {

    case enableHapticFeedback,
         useWheelchair,
         // versions
         mapVersion,
         mapLibreVersion,
         positioningVersion,
         // Core constants
         itineraryRecalculationEnabled,
         userLocationProjectionOnItineraryEnabled,
         userLocationProjectionOnGraphEnabled,
         pointsOfInterestLoadingTimeoutSeconds,
         // Map constants
         switchLevelsAutomaticallyOnUserMovements,
         staleStateTimeout,
         // VPS constants
         accurateStateAccuracy,
         degradedStateAccuracy,
         attitudeAccuracy,
         cameraImageMaxSizeSmallerSide,
         useJPGImageForVPS,
         jpgImageCompressionQuality,
         // VPSController
         slowConnectionSeconds,
         useGrayscaleImageForVPS,
         minInclinationAngle,
         backgroundScanMinInclinationAngle,
         backgroundScanTimeInterval,
         backgroundScanDistanceThreshold,
         maxCannotLocalizeErrorCount,
         // StateManager
         degradedDistanceThreshold,
         notPositioningDistanceThreshold,
         // Static detector constants
         staticPositionDetectorWindowDurationSeconds,
         staticPositionDetectorGeofenceRadiusMeters,
         // Conveing detector constants
         conveyingDetectorDurationSeconds,
         conveyingDetectorElevatorBufferRadius,
         conveyingDetectorLinearConveyingBufferOffset,
         // Global navigation options
         arrivedDistanceThreshold,
         userPositionThreshold,
         navigationRecalculationTimeInterval
}

enum AppConstants {
    nonisolated(unsafe) static var enableHapticFeedback: Bool = true
    nonisolated(unsafe) static var useWheelchair: Bool = false
}

func makeSessionConfig() -> SessionConfig {
    .init(
        itineraryRecalculationEnabled: UserDefaults.bool(
            forKey: .itineraryRecalculationEnabled, defaultValue: true
        ),
        userLocationProjectionOnItineraryEnabled: UserDefaults.bool(
            forKey: .userLocationProjectionOnItineraryEnabled, defaultValue: true
        ),
        userLocationProjectionOnGraphEnabled: UserDefaults.bool(
            forKey: .userLocationProjectionOnGraphEnabled, defaultValue: false
        ),
        pointsOfInterestLoadingTimeout: .seconds(UserDefaults.int(
            forKey: .pointsOfInterestLoadingTimeoutSeconds, defaultValue: 10
        ))
    )
}

func makeMapViewConfig() -> MapViewConfig {
    .init(
        switchLevelsAutomaticallyOnUserMovements: UserDefaults.bool(
            forKey: .switchLevelsAutomaticallyOnUserMovements, defaultValue: true
        ),
        staleStateTimeout: .seconds(UserDefaults.int(forKey: .staleStateTimeout, defaultValue: 5))
    )
}

func makeVPSConfig() -> VPSConfig {
    // Use nil for optional fields equal to the default, so the map configuration can provide them instead.
    let rawScanInterval = UserDefaults.double(forKey: .backgroundScanTimeInterval, defaultValue: 30)
    let rawForegroundAngle = UserDefaults.double(forKey: .minInclinationAngle, defaultValue: 65)
    return .init(
        locationSource: .init(
            accurateStateAccuracy: UserDefaults.double(forKey: .accurateStateAccuracy, defaultValue: 1),
            degradedStateAccuracy: UserDefaults.double(forKey: .degradedStateAccuracy, defaultValue: 5),
            attitudeAccuracy: UserDefaults.double(forKey: .attitudeAccuracy, defaultValue: 35)
        ),
        controller: .init(
            backgroundScanTimeInterval: rawScanInterval == 30 ? nil : rawScanInterval,
            backgroundScanDistanceThreshold: UserDefaults.double(forKey: .backgroundScanDistanceThreshold, defaultValue: 15),
            backgroundScanFailureResetThreshold: 10,
            foregroundScanMinInclinationAngle: rawForegroundAngle == 65 ? nil : rawForegroundAngle,
            backgroundScanMinInclinationAngle: UserDefaults.double(forKey: .backgroundScanMinInclinationAngle, defaultValue: 75),
            slowConnectionTimeout: .seconds(UserDefaults.int(forKey: .slowConnectionSeconds, defaultValue: 5)),
            useGrayscaleImageForVPS: UserDefaults.bool(forKey: .useGrayscaleImageForVPS, defaultValue: false),
            cameraImageMaxSizeSmallerSide: UserDefaults.double(forKey: .cameraImageMaxSizeSmallerSide, defaultValue: 720),
            useJPGImageForVPS: UserDefaults.bool(forKey: .useJPGImageForVPS, defaultValue: true),
            jpgImageCompressionQuality: UserDefaults.int(forKey: .jpgImageCompressionQuality, defaultValue: 70)
        ),
        stateManager: .init(
            degradedDistanceThreshold: UserDefaults.double(forKey: .degradedDistanceThreshold, defaultValue: 75),
            notPositioningDistanceThreshold: UserDefaults.double(forKey: .notPositioningDistanceThreshold, defaultValue: 150)
        ),
        staticPositionDetector: .init(
            windowDuration: UserDefaults.double(forKey: .staticPositionDetectorWindowDurationSeconds, defaultValue: 3),
            geofenceRadius: UserDefaults.double(forKey: .staticPositionDetectorGeofenceRadiusMeters, defaultValue: 1)
        ),
        conveyingDetector: .init(
            duration: .seconds(UserDefaults.int(forKey: .conveyingDetectorDurationSeconds, defaultValue: 3)),
            elevatorBufferRadius: UserDefaults.double(forKey: .conveyingDetectorElevatorBufferRadius, defaultValue: 5),
            linearConveyingBufferOffset: UserDefaults.double(forKey: .conveyingDetectorLinearConveyingBufferOffset, defaultValue: 3)
        )
    )
}

func sdkVersions() -> [String: Any] {

    AppConstants.enableHapticFeedback = UserDefaults
        .bool(forKey: .enableHapticFeedback, defaultValue: AppConstants.enableHapticFeedback)

    AppConstants.useWheelchair = UserDefaults
        .bool(forKey: .useWheelchair, defaultValue: AppConstants.useWheelchair)

    let specificKeysAndValues: [PreferencesKey: Any] = [
        .mapVersion: Bundle.map.version,
        .mapLibreVersion: Bundle.mapLibre.version,
        .positioningVersion: Bundle.positioningVPSARKit.version
    ]

    return Dictionary(uniqueKeysWithValues: specificKeysAndValues.map { ($0.rawValue, $1) })
}
