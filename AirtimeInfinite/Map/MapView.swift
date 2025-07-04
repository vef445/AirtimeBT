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
        var weatherAnnotation: WeatherAnnotation?   // Keep a reference to the weather annotation
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        // Calculate the upper-left coordinate of the visible map region
        func upperLeftCoordinate(of mapView: MKMapView) -> CLLocationCoordinate2D {
            let region = mapView.region
            let center = region.center
            let span = region.span
            
            var lat = center.latitude + span.latitudeDelta / 2
            var lon = center.longitude - span.longitudeDelta / 2
            
            // Shift x% towards center horizontally and vertically
                lat -= span.latitudeDelta * 0.3
                lon += span.longitudeDelta * 0.3
            
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        
        // Called whenever the visible region changes (user pans/zooms)
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard let annotation = weatherAnnotation else { return }
            annotation.coordinate = upperLeftCoordinate(of: mapView)
        }
        
        // Existing polyline renderer code
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let polylineRenderer = MKPolylineRenderer(overlay: polyline)
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
        
        // Draw arrow for wind direction indication
        func makeArrowImage(length: CGFloat = 40, thickness: CGFloat = 6, color: UIColor = .blue) -> UIImage {
            let size = CGSize(width: length, height: length)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                ctx.cgContext.setFillColor(color.cgColor)
                let shaftRect = CGRect(x: size.width/2 - thickness/2, y: size.height * 0.3, width: thickness, height: size.height * 0.6)
                ctx.cgContext.fill(shaftRect)
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: CGPoint(x: size.width/2, y: 0))
                ctx.cgContext.addLine(to: CGPoint(x: size.width/2 - thickness, y: size.height * 0.3))
                ctx.cgContext.addLine(to: CGPoint(x: size.width/2 + thickness, y: size.height * 0.3))
                ctx.cgContext.closePath()
                ctx.cgContext.fillPath()
            }
        }
        
        // Annotation view for weather and other annotations
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let weatherAnnotation = annotation as? WeatherAnnotation {
                let identifier = "weatherAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.image = makeArrowImage()
                    
                    // Add temperature and humidity in callout
                    let label = UILabel()
                    label.numberOfLines = 2
                    label.font = UIFont.systemFont(ofSize: 12)
                    label.text = String(format: "Temp: %.1f°C\nHum: %.0f%%", weatherAnnotation.temperature, weatherAnnotation.humidity)
                    annotationView?.detailCalloutAccessoryView = label
                    
                    // Save reference to this annotation so we can update it later
                    self.weatherAnnotation = weatherAnnotation
                    
                    // Set initial coordinate to upper-left corner
                    weatherAnnotation.coordinate = upperLeftCoordinate(of: mapView)
                    
                } else {
                    annotationView?.annotation = annotation
                    annotationView?.image = makeArrowImage()
                }
                
                // Rotate arrow based on wind direction
                let rotation = CGFloat((weatherAnnotation.windDirection + 180) * .pi / 180)
                annotationView?.transform = CGAffineTransform(rotationAngle: rotation)
                
                return annotationView
            }
            
            // Fallback for your other annotations
            let identifier = "selectedDataPoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.image = UIImage(systemName: "largecircle.fill.circle")
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}

