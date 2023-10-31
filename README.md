# Wemap SDK Sample apps iOS

![Wemap](icon.png)

## Requirements

* Xcode 14+
* Swift 5+
* Gems - using Bundler and Gemfile or manually
  * cocoapods
  * cocoapods-s3-download

## Installation

* download repository

* install necessary gems using Bundler and Gemfile or manually

    ``` shell
    bundle install
    ```

* run in console in project folder

    ``` shell
    export AWS_ACCESS_KEY_ID=*** && \
    export AWS_SECRET_ACCESS_KEY=*** && \
    export AWS_REGION=*** && \
    [bundle exec] pod install --repo-update
    ```

* open `WemapExamples.xcworkspace`

* specify `mapID` and `token` and optionally `polestarApiKey` in Examples:
  * [`Map`](Examples/Map/Sources/Constants.swift)
  * [`Map+Positioning`](Examples/Map+Positioning/Sources/Constants.swift)

* build and run desired example app scheme

## Examples

* MapExample

  * Levels - shows how to set custom indoor location provider and switch between levels
  * Points of interests - shows how to perform selection of POIs on the map
  * Navigation - shows how to start navigation to some user-created annotation

* Map+PositioningExample
