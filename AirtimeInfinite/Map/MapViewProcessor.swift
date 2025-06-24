//
//  MapViewProcessor.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import MapKit
import SwiftUI

/// Data handler for the Map view
class MapViewProcessor {
    
    var mapView: MKMapView
    
    init() {
        mapView = MKMapView()
    }
    
    static let measureTitle = "measure"
    /**
    Processes and displays user-selected track data to the map
    
    - Parameters:
       - track: Object containing all track data
    */
    func loadTrack(track: Track) {
        let coordinatesList = track.getCoordinatesList()
        let polyLine = MKPolyline(
            coordinates: coordinatesList,
            count: coordinatesList.count)
        self.mapView.addOverlay(polyLine)
        
        self.setMapRegion(trackCoordinates: track.getCoordinatesList())
    }
    
    /**
    Add an annotation for the provided data point
    
    - Parameters:
       - dataPoint: DataPoint to mark on the map
    */
    func addSelectedDataPoint(dataPoint: DataPoint){
        /// Remove previous
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.mapView.addAnnotation(dataPoint)
    }
    
    /**
    Add an overlay line for the selected measurement range
    
    - Parameters:
       - : DataPoint to mark on the map
    */
    func addMeasurementOverlay(startMeasure: Double, endMeasure: Double){
        /// Remove previous
        self.removeMeasurementOverlay()
        let coordinatesList = MainProcessor.instance.track.getTrackCoordinatesFromSecondsBounds(firstIndex: startMeasure, lastIndex: endMeasure)
        let polyLine = MKPolyline(
            coordinates: coordinatesList,
            count: coordinatesList.count)
        polyLine.title = MapViewProcessor.measureTitle
        self.mapView.addOverlay(polyLine)
    }
    
    /// Remove the line for measurements
    func removeMeasurementOverlay() {
        for overlay in mapView.overlays {
            if overlay.title != nil && overlay.title == MapViewProcessor.measureTitle  {
                mapView.removeOverlay(overlay)
            }
        }
    }
    
    /// Remove previous lines and locaitons from the map
    func clearMap() {
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotations(self.mapView.annotations)
    }
    
    /**
    Set the map view region given a set of coordiantes
    
    - Parameters:
       - trackCoordiantes: List of all coordiantes to be displayed in a track
    */
    func setMapRegion(trackCoordinates: [CLLocationCoordinate2D]) {
        let boundsProcessor = MapBoundryProcessor(trackCoordinates: trackCoordinates)
        let viewMeters = boundsProcessor.getTrackDiagonalBoundsDistance()
        let middleCoordiantes = boundsProcessor.getGeographicCenter()
        
        let viewRegion = MKCoordinateRegion(
            center: middleCoordiantes,
            latitudinalMeters: viewMeters,
            longitudinalMeters: viewMeters)
        
        self.mapView.setRegion(viewRegion, animated: true)
    }
}
