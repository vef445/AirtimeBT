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
        
        /// Credit: https://www.hackingwithswift.com/books/ios-swiftui/customizing-mkmapview-annotations
        /// Place a dot on the user selected point
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
