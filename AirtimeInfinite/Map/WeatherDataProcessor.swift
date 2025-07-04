//
//  WeatherDataProcessor.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 03/07/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import Foundation
import CoreLocation

class WeatherDataProcessor {
    static let shared = WeatherDataProcessor()
    
    private init() {}
    
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at date: Date, completion: @escaping (WeatherAnnotation?) -> Void) {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let apiKey = "AVH9MV4FVWZVJDN7CKEBB8LDH"
        let urlStr = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/\(lat),\(lon)/\(dateString)?unitGroup=metric&key=\(apiKey)&include=hours"
        
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
       // print("Weather API URL: \(urlStr)")
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                if let error = error {
                    print("Weather API error: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let days = json?["days"] as? [[String: Any]], let day = days.first,
                   let hours = day["hours"] as? [[String: Any]] {
                    
                    // Find closest hour to date
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // or your desired timezone

                    if let closestHour = hours.min(by: { hour1, hour2 in
                        func hourDate(from hourDict: [String: Any]) -> Date? {
                            guard let hourString = hourDict["datetime"] as? String else { return nil }
                            let fullDateString = "\(dateString)T\(hourString)"
                            return dateFormatter.date(from: fullDateString)
                        }

                        guard let t1 = hourDate(from: hour1), let t2 = hourDate(from: hour2) else {
                            return false
                        }
                        return abs(t1.timeIntervalSince(date)) < abs(t2.timeIntervalSince(date))
                    }) {
                        let temp = closestHour["temp"] as? Double ?? 0.0
                        let hum = closestHour["humidity"] as? Double ?? 0.0
                        let windSpeed = closestHour["windspeed"] as? Double ?? 0.0
                        let windDir = closestHour["winddir"] as? Double ?? 0.0
                        
                        let annotation = WeatherAnnotation(coordinate: coordinate, temperature: temp, humidity: hum, windSpeed: windSpeed, windDirection: windDir)
                        
                        DispatchQueue.main.async {
                            /*
                            print("""
                            ✅ Weather Annotation Created:
                            - Temp: \(temp)
                            - Humidity: \(hum)
                            - Wind Speed: \(windSpeed)
                            - Wind Dir: \(windDir)
                            """)
                             */

                            completion(annotation)
                        }
                        return
                    }
                }
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                if let rawString = String(data: data, encoding: .utf8) {
                    print("Weather API raw response: \(rawString)")
                }
                print("Weather API parsing error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
}
