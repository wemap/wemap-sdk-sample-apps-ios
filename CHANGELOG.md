# Change Log

---

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

### Added

* MapSDK: switch level automatically on selectPOI if shouldCenter is true
* MapSDK: add new events when a POI is selected/unselected

### Fixed

* MapSDK: Stop event did not reach even if remaining distance is less than threshold
* MapSDK: Navigation info is wrong when itinerary contains indoor and outdoor parts
* MapSDK: click on the PoI symbol (shape) does not select the PoI
