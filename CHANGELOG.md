# Change Log

---

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
