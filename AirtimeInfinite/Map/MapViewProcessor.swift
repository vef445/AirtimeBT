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
class MapViewProcessor: NSObject, MKMapViewDelegate {
    
    var mapView: MKMapView
    var weatherAnnotations: [WeatherAnnotation] = []

    
    override init() {
        mapView = MKMapView()
        super.init()
        mapView.delegate = self
    }
    
    static let measureTitle = "measure"
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is WeatherAnnotation {
            let identifier = "WeatherAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true

                // Example customization:
                annotationView!.markerTintColor = .blue

                // Add details as subtitle
                if let weather = annotation as? WeatherAnnotation {
                    let tempString = String(format: "%.1f°C", weather.temperature)
                    let windString = String(format: "%.1f km/h %@", weather.windSpeed, windDirectionString(from: weather.windDirection))

                    let label = UILabel()
                    label.numberOfLines = 2
                    label.text = "Temp: \(tempString)\nWind: \(windString)"
                    annotationView!.detailCalloutAccessoryView = label
                }
            } else {
                annotationView!.annotation = annotation
            }

            return annotationView
        }

        return nil
    }

    func windDirectionString(from degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((degrees + 22.5) / 45.0) & 7
        return directions[index]
    }
    
    
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
        
        //Fetch weather data
        fetchWeatherData(for: track)
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
    
    //Retrieve position on the map to display weather info
    func upperLeftCoordinate(of mapView: MKMapView) -> CLLocationCoordinate2D {
        let region = mapView.region
        let center = region.center
        let span = region.span
        
        // Upper-left means:
        // latitude = center.latitude + half of latitude span
        // longitude = center.longitude - half of longitude span
        let lat = center.latitude + span.latitudeDelta / 2
        let lon = center.longitude - span.longitudeDelta / 2
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    
    func fetchWeatherData(for track: Track) {
        guard let point = track.getCoordinatesAndTimes() else {
            print("No points available")
            return
        }
        
        let coord = upperLeftCoordinate(of: mapView)
        let date = point.date
        
        WeatherDataProcessor.shared.fetchWeather(for: coord, at: date) { annotation in
            DispatchQueue.main.async {
                // Remove old weather annotations
                self.mapView.removeAnnotations(self.weatherAnnotations)
                self.weatherAnnotations.removeAll()
                
                if let annotation = annotation {
                    self.weatherAnnotations.append(annotation)
                    //print("Adding weather annotation at \(annotation.coordinate), temp: \(annotation.temperature)")
                    self.mapView.addAnnotation(annotation)
                } else {
                    print("No weather data found for point at \(coord)")
                }
            }
        }
    }
}
