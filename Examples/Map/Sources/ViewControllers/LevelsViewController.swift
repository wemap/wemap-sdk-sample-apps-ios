//
//  LevelsViewController.swift
//  MapExamples
//
//  Created by Evgenii Khrushchev on 22/03/2023.
//  Copyright © 2023 Wemap SAS. All rights reserved.
//

import MapLibre
import Turf
import UIKit
import WemapCoreSDK
import WemapMapSDK

final class LevelsViewController: MapViewController {

    private enum CircleConstants {
        static let sourceID = "center-circle-source"
        static let layerID = "center-circle-layer"
        static let radius = 100.0 // meters
        static let vertices = 64
    }

    private var uniqueLevels: Set<Float> = []

    private var pois: Set<PointOfInterest> {
        pointOfInterestManager.getPOIs()
    }

    override func lateInit() {
        super.lateInit()
        uniqueLevels = Set(pois.compactMap(\.coordinate.levels.first))
        drawCircleAroundCenter()
    }

    /// Draws a 100 meters radius circle outline around the current center of the map.
    /// Only the circle border is visible - there is no fill, so the map underneath stays visible.
    private func drawCircleAroundCenter() {

        guard let style = map.style else {
            return debugPrint("Failed to draw circle because the style is not loaded yet")
        }

        // remove a previously drawn circle to keep the method idempotent
        if let existingLayer = style.layer(withIdentifier: CircleConstants.layerID) {
            style.removeLayer(existingLayer)
        }
        if let existingSource = style.source(withIdentifier: CircleConstants.sourceID) {
            style.removeSource(existingSource)
        }

        // Turf generates the circle as a polygon ring for us, given a metric radius
        let circle = Polygon(center: map.centerCoordinate, radius: CircleConstants.radius, vertices: CircleConstants.vertices)

        // use the outer ring as a polyline so only the border is rendered (line layer = no fill)
        var ring = circle.coordinates[0]
        let polyline = MLNPolylineFeature(coordinates: &ring, count: UInt(ring.count))
        let source = MLNShapeSource(identifier: CircleConstants.sourceID, shape: polyline, options: nil)
        style.addSource(source)

        let layer = MLNLineStyleLayer(identifier: CircleConstants.layerID, source: source)
        layer.lineColor = NSExpression(forConstantValue: UIColor.red)
        layer.lineWidth = NSExpression(forConstantValue: 2)
        layer.lineJoin = NSExpression(forConstantValue: "round")
        style.addLayer(layer)
    }
    
    @IBAction func closeTouched() {
        dismiss(animated: true)
    }
    
    @IBAction func firstTouched() {
        
        guard let minLevel = uniqueLevels.min() else {
            return debugPrint("Failed to select POI on min level because there are no levels")
        }
        
        selectPOI(atLevel: minLevel)
    }
    
    @IBAction func secondTouched() {
        guard let maxLevel = uniqueLevels.max() else {
            return debugPrint("Failed to select POI on max level because there are no levels")
        }
        
        selectPOI(atLevel: maxLevel)
    }
    
    private func selectPOI(atLevel level: Float) {
        
        guard let randomPOI = pois.filter({ LevelUtils.intersects($0.coordinate.levels, [level]) }).randomElement() else {
            return debugPrint("Failed to get random POI at level \(level)")
        }
        
        pointOfInterestManager.selectPOI(randomPOI)
    }
}
