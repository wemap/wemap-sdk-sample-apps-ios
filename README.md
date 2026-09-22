# Wemap SDK Sample apps iOS

![Wemap](icon.png)

## Requirements

* iOS 15.0 or newer
* Xcode 26.0 or newer
* Swift 6.2 or newer

## Installation

* download repository

* open `Examples.xcodeproj`

* modify `mapID` and `token` [here in Constants](./Examples/Sources/Constants.swift)

* build and run desired example app scheme

## Upgrading to 1.0

**1.0 is a breaking release.** Every sample here is written against the new API, so it doubles as a
worked example of the migration. The three changes you will meet first:

* **Sessions replace the singletons.** `WemapCore.shared` and `WemapMap.shared` are gone; a screen creates
  a `CoreSession` or `MapSession` with an `async throws` init and passes it to the views and location
  sources that need it. `InitialViewController` in each app shows the creation, and the sharing of one
  session across a map and an AR view.
* **`AsyncStream` replaces the delegates.** `MapViewDelegate`, `GeoARViewDelegate` and the Combine
  publishers are gone — views report loading through `LoadPhase`, and managers publish events as
  `AsyncStream` properties consumed from a `Task`.
* **Immutable configs replace the global constants.** `MapConstants`, `ARConstants` and friends are gone;
  each app's `Config.swift` builds a value-type config at session or view creation time.

The full guide, ordered so each step leaves your project compiling, ships with the SDK's API reference.
See the [Wemap SDKs for iOS documentation](https://developers.getwemap.com/docs/ios-native/getting-started)
and the [release notes](https://github.com/wemap/wemap-sdk-ios-distribution/releases).

## Examples

* Map
  * Levels - Shows how to set custom indoor location provider and switch between levels
  * Points of interests - Shows how to hide/show and select/unselect POIs
  * Navigation - Shows how to start navigation to user-created annotation
  * Map in SwiftUI - The map, its bindings and its events in one SwiftUI screen
  * Custom credits - Shows how to override default credits action sheet and setup accessibility

* Map+Positioning. Shows how to connect different Location Sources to `WemapMapSDK`.

* Positioning. Shows how to work VPS Location source without `WemapMapSDK`. For example if you want to connect `WemapPositioningSDK/VPSARKit` to your own map.

* Positioning+AR. Shows how to connect different Location Sources to `WemapGeoARSDK`.
