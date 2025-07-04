//
//  WeatherAnnotation.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 03/07/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//
import MapKit

class WeatherAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var temperature: Double
    var humidity: Double
    var windSpeed: Double
    var windDirection: Double
    
    var title: String? {
        return String(format: "%.1f°C, %.1f km/h", temperature, windSpeed)
    }
    
    var subtitle: String? {
        return String(format: "Humidity: %.0f%%, Wind Dir: %.0f°", humidity, windDirection)
    }
    
    init(coordinate: CLLocationCoordinate2D, temperature: Double, humidity: Double, windSpeed: Double, windDirection: Double) {
        self.coordinate = coordinate
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
    }
}
