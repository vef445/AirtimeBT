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
    var pendingWeatherCoordinate: CLLocationCoordinate2D?
    var pendingWeatherDate: Date?
    var currentTrack: Track?
    
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
        self.currentTrack = track
        track.weatherFetchedForCurrentTrack = false // Reset flag for new track

        let coordinatesList = track.getCoordinatesList()
        let polyLine = MKPolyline(coordinates: coordinatesList, count: coordinatesList.count)
        self.mapView.addOverlay(polyLine)

        if let lastDate = track.dateTime {
            self.setMapRegion(trackCoordinates: coordinatesList, at: lastDate)

            // Save pending weather info to fetch after zoom
            if let insetCoordinate = getInsetTopLeftFromVisibleMapRect() {
                pendingWeatherCoordinate = insetCoordinate
                pendingWeatherDate = lastDate
            }
        } else {
            print("No date found, using current date")
        }
    }
    /* For future use
    func tryFetchWeatherIfNeeded() {
        guard let coord = pendingWeatherCoordinate,
              let date = pendingWeatherDate,
              let track = self.currentTrack,
              !track.weatherFetchedForCurrentTrack else {
            return
        }
        fetchWeather(at: coord, date: date)
        track.weatherFetchedForCurrentTrack = true
    }
*/

    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard let date = pendingWeatherDate,
              let track = self.currentTrack,
              !track.weatherFetchedForCurrentTrack else {
            return
        }

        // Calculate inset coordinate *after* the region has changed
        let coord = getInsetTopLeftFromVisibleMapRect(insetMeters: 1000) ?? mapView.centerCoordinate

        //fetchWeather(at: coord, date: date)
        track.weatherFetchedForCurrentTrack = true
        
        // Clear pending
        pendingWeatherDate = nil
    }

    
    /**
    Add an annotation for the provided data point
    
    - Parameters:
       - dataPoint: DataPoint to mark on the map
    */
    func addSelectedDataPoint(dataPoint: DataPoint){
        // Remove all annotations except WeatherAnnotation
        for annotation in self.mapView.annotations {
            if !(annotation is WeatherAnnotation) {
                self.mapView.removeAnnotation(annotation)
            }
        }
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
    func getInsetTopLeftFromVisibleMapRect(insetMeters: CLLocationDistance = 1000) -> CLLocationCoordinate2D? {
        let visibleRect = self.mapView.visibleMapRect

        // Top-left map point of visible rect (minX, minY)
        let topLeftMapPoint = MKMapPoint(x: visibleRect.minX, y: visibleRect.minY)
        
        // Convert to coordinate
        let topLeftCoordinate = topLeftMapPoint.coordinate

        // Calculate latitude and longitude offsets in degrees for insetMeters
        let metersPerDegreeLat = 111_000.0
        let latInsetDegrees = insetMeters / metersPerDegreeLat

        let metersPerDegreeLon = metersPerDegreeLat * cos(topLeftCoordinate.latitude * .pi / 180)
        let lonInsetDegrees = insetMeters / metersPerDegreeLon

        // Move coordinate *down* (lat decreases) and *left* (lon decreases) for inset inside map view
        let insetLat = topLeftCoordinate.latitude - latInsetDegrees
        let insetLon = topLeftCoordinate.longitude - lonInsetDegrees

        return CLLocationCoordinate2D(latitude: insetLat, longitude: insetLon)
    }

/* For future use
    private func fetchWeather(at coordinate: CLLocationCoordinate2D, date: Date) {
        WeatherDataProcessor.shared.fetchWeather(for: coordinate, at: date) { [weak self] weatherAnnotation in
            guard let self = self, let annotation = weatherAnnotation else { return }

            let existingWeatherAnnotations = self.mapView.annotations.compactMap { $0 as? WeatherAnnotation }
            self.mapView.removeAnnotations(existingWeatherAnnotations)
            self.mapView.addAnnotation(annotation)
            self.currentTrack?.weatherFetchedForCurrentTrack = true
        }
    }
 */
    
    func setMapRegion(trackCoordinates: [CLLocationCoordinate2D], at date: Date) {
        let boundsProcessor = MapBoundryProcessor(trackCoordinates: trackCoordinates)
        let viewMeters = boundsProcessor.getTrackDiagonalBoundsDistance()
        let middleCoordinates = boundsProcessor.getGeographicCenter()

        let zoomFactor = 1.5
        let viewRegion = MKCoordinateRegion(
            center: middleCoordinates,
            latitudinalMeters: viewMeters * zoomFactor,
            longitudinalMeters: viewMeters * zoomFactor
        )
        
        self.mapView.setRegion(viewRegion, animated: true)
        
        // Instead of setting pendingWeatherCoordinate now, defer until regionDidChangeAnimated
        pendingWeatherDate = date
    }
}
