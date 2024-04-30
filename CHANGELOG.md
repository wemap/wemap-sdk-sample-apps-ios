# Change Log

---

## [0.15.0]

### Breaking changes

* `LevelChange.direction: String` has been changed to `LevelChange.direction: Incline`
* `Step` has been changed:
  * `let isGate: Bool` has been moved to `extras.isGate`
  * `let subwayEntranceName: String?` has been moved to `extras.subwayEntranceName`
* `Leg` has been changed:
  * `let start: Coordinate` has been changed to `let start: Destination`
  * `let end: Coordinate` has been changed to `let end: Destination`
* `ItinerariesParametersMultipleDestinations` has been renamed to `ItinerariesParametersMultiDestinations`
* `ItinerarySearchOptions` has been replaced everywhere from nullable parameter to parameter with a default value

### Added

* PosSDK(VPS): add checkVpsAvailability() method
* MapSDK: offline maps support

### Fixed

* PosSDK(VPS): wrong level detection if altitude < 0 

### Dependencies

* MapLibre 6.2.0 -> 6.4.0
* RxSwift 6.6.0 -> 6.7.0

## [0.14.3]

### Fixed

* PosSDK: Polestar LocationSource does not work

### Dependencies

* NAOSDK 4.11.14 -> 4.11.15

## [0.14.2]

### Fixed

* MapSDK: centerToPOI fails if POI doesn't have level or there is no building in focus

## [0.14.1]

### Fixed

* MapSDK: allow POIs that are not attached to the building to be shown on the map

## [0.14.0]

### Breaking changes

* `NavigationInfo` and `NavigationInfoHandler` have been moved from `WemapMapSDK` to `WemapCoreSDK`

### Added

* CoreSDK: add optional mapId parameter to ItineraryParameters

### Changed

* CoreSDK: Make NavigationInfoHandler usable without MapSDK

### Dependencies

* MapLibre 6.1.1 -> 6.2.0
* Alamofire 5.8.1 -> 5.9.0

## [0.13.0]

### Breaking changes

* Due to migration from MapLibre 5.13.0 to [6.1.1](https://github.com/maplibre/maplibre-native/releases/tag/ios-v6.0.0) additional changes needed:
  * Changed the prefix of files, classes, methods, variables and everything from `MGL` to `MLN`. If you are using NSKeyedArchiver or similar mechanishm to save the state, the app may crash after this change when trying to unarchive the state using old names of the classes. You need to clean the saved state of the app and save it using new classes.
  * The Swift package needs to be imported with `import MapLibre` instead of `import Mapbox`.
* removed support for iOS 11
* `VPSARKitLocationSource.State.limited(reason: VPSARKitLocationSource.State.Reason)` has been changed to `VPSARKitLocationSource.State.limited(reason: ARCamera.TrackingState.Reason)`:
  * `VPSARKitLocationSource.State.Reason.correction` has been removed
* `WemapMapViewDelegate.map(_: MapView, didTouchFeature feature: MGLFeature)` and `WemapMapViewDelegate.map(_ map: MapView, didTouchPointOfInterest poi: PointOfInterest)` delegate methods have been removed.
Use `PointOfInterestManagerDelegate.pointOfInterestManager(_: PointOfInterestManager, didTouchPointOfInterest poi: PointOfInterest)` or `PointOfInterestManagerDelegate.pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest)` instead.
* `WemapMap.setEnvironment(_: Environment)` has been moved to `WemapCore.setEnvironment(_: Environment)`
* `Itinerary` has been changed:
  * `let from: Coordinate` has been renamed to `let origin: Coordinate`
  * `let to: Coordinate` has been renamed to `let destination: Coordinate`
  * `let mode: TravelMode` has been renamed to `let transitMode: TravelMode`
* `Leg` has been changed:
  * `let from: Coordinate` has been renamed to `let start: Coordinate`
  * `let to: Coordinate` has been renamed to `let end: Coordinate`
  * `let mode: TravelMode` has been renamed to `let transitMode: TravelMode`
* `TravelMode.bike` has been changed to `TravelMode.bike(preference: TravelMode.Preference)`
* `ItineraryParameters.init(from: Coordinate, to: Coordinate, mode: TravelMode, options: ItinerarySearchOptions)` has been changed to `ItineraryParameters.init(origin: Coordinate, destination: Coordinate, travelMode: TravelMode, searchOptions: ItinerarySearchOptions?)`
* `ItineraryParametersMultipleDestinations` has been renamed to `ItinerariesParametersMultipleDestinations`:
  * `init(origin: Coordinate, pointsOfInterest: [PointOfInterest], mapId: Int, mode: TravelMode, options: ItinerarySearchOptions)` has been changed to `init(origin: Coordinate, pointsOfInterest: [PointOfInterest], mapId: Int, travelMode: TravelMode, searchOptions: ItinerarySearchOptions?)`
  * `init(origin: Coordinate, coordinates: [Coordinate], mapId: Int?, mode: TravelMode, options: ItinerarySearchOptions)` has been changed to `init(origin: Coordinate, coordinates: [Coordinate], mapId: Int?, travelMode: TravelMode, searchOptions: ItinerarySearchOptions?)`
* `ItinerarySearchOptions` has been changed:
  * `let useStairs: Bool` has been replaced by `let avoidStairs: Bool`
  * `let useEscalators: Bool` has been replaced by `let avoidEscalators: Bool`
  * `let useElevators: Bool` has been replaced by `let avoidElevators: Bool`
* `ItinerariesResponse` has been changed:
  * `let from: Coordinate` has been removed
  * `let to: Coordinate` has been removed
  * `let error: String?` has been replaced by `let status: Status`
* `ItineraryManager` has been changed:
  * `getItineraries(from: Coordinate, to: Coordinate, searchOptions: ItinerarySearchOptions)` has been changed to `getItineraries(origin: Coordinate, destination: Coordinate, travelMode: TravelMode, searchOptions: ItinerarySearchOptions?)`
* `NavigationManager` has been changed:
  * `startNavigation(from: Coordinate, to: Coordinate, timeout: DispatchTimeInterval, options: NavigationOptions, itinerarySearchOptions: ItinerarySearchOptions)` has been changed to `startNavigation(origin: Coordinate?, destination: Coordinate, travelMode: TravelMode, options: NavigationOptions, searchOptions: ItinerarySearchOptions?, timeout: DispatchTimeInterval)`
  * `startNavigation(_: Itinerary, options: NavigationOptions, itinerarySearchOptions: ItinerarySearchOptions)` has been changed to  `startNavigation(_: Itinerary, options: NavigationOptions, searchOptions: ItinerarySearchOptions?)`

### Added

* CoreSDK: Add fastest, safest, tourism preferences for bike travel mode
* MapSDK: expose pitch from MapData, take into account the initial value
* MapSDK: expose bearing from MapData, take into account the initial value

### Changed

* CoreSDK: migrate to Itineraries API v2
* MapSDK: migrate to MapLibre 6.0.0
* MapSDK: replace didTouchFeature by didTouchPointOfInterest

### Fixed

* MapSDK: some POIs are selected and immediately unselected
* MapSDK: MapView is not deallocated on view dismissal

### Dependencies

* Itineraries API v1 -> v2
* MapLibre 5.13.0 -> 6.1.1
* NAOSwiftProvider 1.2.2 -> 1.3.0

## [0.12.0]

### Breaking changes

* `WemapMap.userLocationManager.userLocationAnnotationViewStyle` has been renamed to `WemapMap.userLocationManager.userLocationViewStyle`
* `UserLocationAnnotationViewStyle` has been renamed to `UserLocationViewStyle`. Also its properties have been renamed accordingly:
  * `puckFillColor` has been renamed to `foregroundTintColor`
  * `puckBorderColor` has been renamed to `backgroundTintColor`
  * `puckArrowFillColor` has been renamed to `headingTintColor`
* `OutOfActiveLevelStyle` properties have been renamed accordingly:
  * `puckFillColor` has been renamed to `foregroundTintColor`
  * `puckArrowFillColor` has been renamed to `headingTintColor`
* `PointOfInterest` has been changed:
  * `coordinate2D` has been moved to `coordinate.coordinate2D`
  * `levelID` has been moved to `coordinate.levels`

### Added

* MapSDK/CoreSDK: Let the possibility to sort PoIs by travel time/distance from UserPosition in a "batch" version
* MapSDK: Add remaining distance to the step to NavigationInfo
* MapSDK: PointOfInterest should have a field "Coordinate" to avoid manual transformation later (i.e. nav to a POI)
* MapSDK: Let the possibility to the developer to disable/enable PoI selection
* MapSDK: Add the possibility to change the user location icon dynamically
* MapSDK: ability to change color of outdoor part of itinerary

### Changed

* MapSDK: make NavigationInstructions attributes public

### Fixed

* MapSDK: navigation details steps order is wrong
* MapSDK: filterByTag method do the opposite of the desired effect
* MapSDK: building's active level is reset when viewport has significantly changed even if the building is still in focus
* MapSDK: outdoor part of itinerary is visible only when selected level 0
* MapSDK: blue dot greyed outdoor when camera is following the user

### Dependencies

* Turf 2.7.0 -> 2.8.0
* NAOSDK 4.11.13.1 -> 4.11.14

## [0.11.0]

### Breaking changes

* `LocationSourceSimulator` has been renamed to `SimulatorLocationSource`
* `NavigationDelegate` has been renamed to `NavigationManagerDelegate`
* `WemapMap.getStyleURL(withMapID:token:)` has been renamed to `WemapMap.getMapData(mapID:token:)`
* `PolestarLocationSource` has been moved to `WemapPositioningSDKPolestar` framework
* `VPSARKit*` classes have been moved from `WemapPositioningSDK` to `WemapPositioningSDKVPSARKit` framework

### Added

* MapSDK: Add NavigationManager.hasActiveNavigation
* MapSDK: have a method to startNavigation with itineraries as parameter
* PosSDK: Add "isAvailable" method to LocationSource
* MapSDK: add possibility to center a POI with optional padding

### Changed

* MapSDK: Refactor (i) button popup

### Fixed

* PosSDK: "Scan Required" state of VPSARKit location source is never reached
* PosSDK: VPS orientation is wrong

## [0.10.0]

### Added

* Map+PositioningExample: add an example app to demonstrate VPS functionality
* MapSDK: Create filter by tags
* MapSDK: Extend MapData with Extras

### Fixed

* MapSDK: fix automatic level change when CameraMode is not tracking
* MapSDK: automatic level switch on user movements freezes/lags the app

### Dependencies

* Alamofire 5.8.0 -> 5.8.1

## [0.9.0]

### Added

* MapSDK: add helper method to translate step data into textual instructions
* CoreSDK: add itinerary search options for backend
* MapSDK: add onMapClick event
* MapSDK: create a default GPS (fused) LocationSource

### Changed

* MapSDK: revert back didTouchFeature delegate method

### Fixed

* CoreSDK: fix Coordinate decoding/encoding
* MapSDK: onMapClick called twice
* MapSDK: outdoors, the user's location annotation is displayed in gray
* MapSDK: user position is not projected on stairs

### Deprecated

* MapSDK: `map(_: MapView, didTouchFeature feature: MGLFeature)` delegate method has been deprecated and will be removed soon. Use `PointOfInterestManagerDelegate.pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest)` instead.

### Dependencies

* Turf 2.6.1 -> 2.7.0
* Alamofire 5.7.1 -> 5.8.0
* RxSwift 6.5.0 -> 6.6.0

## [0.8.0]

### Breaking changes

* `IndoorLocationProvider` has been renamed to `LocationSource` and moved from `WemapMapSDK` to `WemapCoreSDK`
* `IndoorLocationProviderDelegate` has been renamed to `LocationSourceDelegate` and moved from `WemapMapSDK` to `WemapCoreSDK`
* `Polestar` `didLocationChange` should take into account `verticalAccuracy` for proper calculation as shown below

    ``` swift
    func didLocationChange(_ location: CLLocation!) {
        
        let coordinate: Coordinate
        if location.verticalAccuracy < 0 { // outdoor location
            coordinate = Coordinate(location: location)
        } else {
            coordinate = Coordinate(location: location, levels: [Float(location.altitude / 5)])
        }
        
        lastCoordinate = coordinate
        delegate?.locationSource(self, didUpdateLocation: coordinate)
    }
    ```

* `map(_: MapView, didTouchFeature feature: MGLFeature)` is removed in favor of `pointOfInterestManager(_: PointOfInterestManager, didSelectPointOfInterest poi: PointOfInterest)`.
  To receive events from `PointOfInterestManager` you have to implement protocol `PointOfInterestManagerDelegate` and assign it to `map.pointOfInterestManager.delegate = self`

### Added

* MapSDK: switch level automatically on selectPOI if shouldCenter is true
* MapSDK: add new events when a POI is selected/unselected

### Fixed

* MapSDK: Stop event did not reach even if remaining distance is less than threshold
* MapSDK: Navigation info is wrong when itinerary contains indoor and outdoor parts
* MapSDK: click on the PoI symbol (shape) does not select the PoI

## [0.7.2]

### Fixed

* CoreSDK: fix pointOfInterestManager.getPOIs()

## [0.7.1]

### Fixed

* MapSDK: outdoors, the user's location annotation is displayed in gray
* MapSDK: user position is not projected on stairs
* MapSDK: Stop event did not reach even if remaining distance is less than threshold
* MapSDK: Navigation info is wrong when itinerary contains indoor and outdoor parts
* MapSDK: it's possible to remove navigation itinerary using itinerary manager (it should not)
