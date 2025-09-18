//
//  MapBoundryProcessor.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import MapKit

/// Given a subset of track data, provide functions to size map view correctly 
class MapBoundryProcessor {
    
    var minLat: Double
    var minLon: Double
    var maxLat: Double
    var maxLon: Double
    
    /**
     Use provided track data to initialize a processor object to determine appropriate map bounds
     
    - Parameters:
     - trackData: Subset of track data to process
    */
    init(trackCoordinates: [CLLocationCoordinate2D]) {
        let lats = trackCoordinates.map { $0.latitude }
        let lons = trackCoordinates.map { $0.longitude }
        
        self.minLat = lats.min() ?? 0
        self.minLon = lons.min() ?? 0
        self.maxLat = lats.max() ?? 0
        self.maxLon = lons.max() ?? 0
    }
    
    /**
    Get the center point of the currently loaded track
     
     Credit:  https://stackoverflow.com/questions/10559219/determining-midpoint-between-2-coordinates
    - Returns: Center point of current track
    */
    func getGeographicCenter() -> CLLocationCoordinate2D {

        var x = Double(0)
        var y = Double(0)
        var z = Double(0)
        
        let coordinates = [
            CLLocationCoordinate2DMake(minLat, minLon),
            CLLocationCoordinate2DMake(maxLat, maxLon)]
        for coordinate in coordinates {
            let lat = coordinate.latitude.degreesToRadians
            let lon = coordinate.longitude.degreesToRadians
            x += cos(lat) * cos(lon)
            y += cos(lat) * sin(lon)
            z += sin(lat)
        }

        x /= Double(coordinates.count)
        y /= Double(coordinates.count)
        z /= Double(coordinates.count)

        let lon = atan2(y, x)
        let hyp = sqrt(x * x + y * y)
        let lat = atan2(z, hyp)

        return CLLocationCoordinate2D(latitude: lat.radiansToDegrees, longitude: lon.radiansToDegrees)
    }
    
    /**
    Get the diagonal distacne in meters of the map view that contains the currently loaded track
     
    - Returns: Diagonal distance of the view the contains the current track
    */
    func getTrackDiagonalBoundsDistance() -> Double {
        
        let bottomLeft = CLLocation(latitude: minLat, longitude: minLon)
        let topRight = CLLocation(latitude: maxLat, longitude: maxLon)
        
        return topRight.distance(from: bottomLeft)
    }
    
}

extension MapBoundryProcessor {
    /// Get a coordinate inset from the top-left corner of the loaded track bounds by a given distance in meters
    func getInsetTopLeftCoordinate(insetMeters: CLLocationDistance = 1000) -> CLLocationCoordinate2D {
        // Top-left corner of bounding box
        let topLeftLat = maxLat
        let topLeftLon = minLon
        
        // Convert insetMeters to degrees latitude (approximate)
        let metersPerDegreeLat = 111_000.0
        let latInsetDegrees = insetMeters / metersPerDegreeLat
        
        // Longitude depends on latitude
        let metersPerDegreeLon = metersPerDegreeLat * cos(topLeftLat * .pi / 180)
        let lonInsetDegrees = insetMeters / metersPerDegreeLon
        
        // Move coordinate inward by insetDegrees
        let insetLat = topLeftLat - latInsetDegrees
        let insetLon = topLeftLon + lonInsetDegrees
        
        return CLLocationCoordinate2D(latitude: insetLat, longitude: insetLon)
    }
}

