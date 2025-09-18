//
//  MapView.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import MapKit
import SwiftUI

/// Map to display the ground track of a loaded track file
struct MapView: UIViewRepresentable {
    
    @EnvironmentObject var main: MainProcessor
    
    func makeUIView(context: Context) -> MKMapView {
        main.mapViewProcessor.mapView.delegate = context.coordinator
        main.mapViewProcessor.mapView.mapType = .hybrid
        return main.mapViewProcessor.mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        
    }


    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
        
        // Future TODO: Different colors for each section of the track (e.g. freefall, canopy, etc), possibly on chart too
        /// Render the line representing the ground track
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let polylineRenderer = MKPolylineRenderer(overlay: polyline)
                /// Make the measurement lines blue
                if polyline.title != nil && polyline.title == MapViewProcessor.measureTitle {
                    polylineRenderer.strokeColor = .blue
                } else {
                    polylineRenderer.strokeColor = .red
                }
                polylineRenderer.lineWidth = 3
                return polylineRenderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            print("Region did change in Coordinator")

            // Update pendingWeatherCoordinate to inset top-left of visible map rect
            if let insetCoordinate = parent.main.mapViewProcessor.getInsetTopLeftFromVisibleMapRect() {
                parent.main.mapViewProcessor.pendingWeatherCoordinate = insetCoordinate
            } else {
                // fallback: center coordinate
                parent.main.mapViewProcessor.pendingWeatherCoordinate = mapView.centerCoordinate
            }

            // Then try to fetch weather
            //parent.main.mapViewProcessor.tryFetchWeatherIfNeeded()
        }
        
        /// Credit: https://www.hackingwithswift.com/books/ios-swiftui/customizing-mkmapview-annotations
        /// Place a dot on the user selected point
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let weatherAnnotation = annotation as? WeatherAnnotation {
                //print("Weather annotation coordinate: \(weatherAnnotation.coordinate.latitude), \(weatherAnnotation.coordinate.longitude)")
                        //print("Map visible region center: \(mapView.region.center.latitude), \(mapView.region.center.longitude)")
                let identifier = "weatherAnnotation"

                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: weatherAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    
                    // Show thermometer icon
                    annotationView?.image = UIImage(systemName: "thermometer")
                    
                    // Label showing temperature next to icon
                    let tempLabel = UILabel()
                    tempLabel.text = String(format: "%.1f°C", weatherAnnotation.temperature)
                    tempLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
                    tempLabel.textColor = .red
                    tempLabel.backgroundColor = UIColor.white.withAlphaComponent(0.7)
                    tempLabel.sizeToFit()
                    tempLabel.translatesAutoresizingMaskIntoConstraints = false
                    
                    annotationView?.addSubview(tempLabel)
                    
                    // Position label to the right of the icon, centered vertically
                    NSLayoutConstraint.activate([
                        tempLabel.leadingAnchor.constraint(equalTo: annotationView!.trailingAnchor, constant: 4),
                        tempLabel.centerYAnchor.constraint(equalTo: annotationView!.centerYAnchor)
                    ])
                } else {
                    annotationView?.annotation = weatherAnnotation
                }

                return annotationView
            }
            
            // Existing circle icon for other annotations (e.g., DataPoint)
            let identifier = "selectedDataPoint"

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.image = UIImage(systemName: "largecircle.fill.circle")
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }

    }
}
