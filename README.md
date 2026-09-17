# Wemap SDK Sample apps iOS

![Wemap](icon.png)

## Requirements

* iOS 13 or newer
* Xcode 26.0 or newer
* Swift 5.10 or newer

## Installation

* download repository

* open `Examples.xcodeproj`

* modify `mapID` and `token` [here in Constants](./Examples/Sources/Constants.swift)

* build and run desired example app scheme

### Building with Xcode 27

The sample apps target **iOS 13.0**, matching the SDK. Xcode 27 refuses any deployment target below
**iOS 15.0** — its SDK sets `SupportedTargets.iphoneos.MinimumDeploymentTarget = 15.0` — so a build fails with:

```
error: The iOS Simulator deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0,
but the range of supported deployment target versions is 15.0 to 27.0.x.
```

To run them under Xcode 27, raise the deployment target to 15.0 for that build only:

```bash
xcodebuild -project Examples.xcodeproj -scheme MapExample IPHONEOS_DEPLOYMENT_TARGET=15.0
```

or set **iOS 15.0** in the target's *Minimum Deployments* in Xcode. iOS 13 remains the supported floor for both
the SDK and these samples — Xcode 26.x builds them as-is, with no override needed.

## Examples

* Map
  * Levels - Shows how to set custom indoor location provider and switch between levels
  * Points of interests - Shows how to hide/show and select/unselect POIs
  * Navigation - Shows how to start navigation to user-created annotation
  * Custom credits - Shows how to override default credits action sheet and setup accessibility

* Map+Positioning. Shows how to connect different Location Sources to `WemapMapSDK`.

* Positioning. Shows how to work VPS Location source without `WemapMapSDK`. For example if you want to connect `WemapPositioningSDK/VPSARKit` to your own map.

* Positioning+AR. Shows how to connect different Location Sources to `WemapGeoARSDK`.
