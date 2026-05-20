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

## Examples

* Map
  * Levels - Shows how to set custom indoor location provider and switch between levels
  * Points of interests - Shows how to hide/show and select/unselect POIs
  * Navigation - Shows how to start navigation to user-created annotation
  * Custom credits - Shows how to override default credits action sheet and setup accessibility

* Map+Positioning. Shows how to connect different Location Sources to `WemapMapSDK`.

* Positioning. Shows how to work VPS Location source without `WemapMapSDK`. For example if you want to connect `WemapPositioningSDK/VPSARKit` to your own map.

* Positioning+AR. Shows how to connect different Location Sources to `WemapGeoARSDK`.
