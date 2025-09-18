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
    
    // Native timezone fetch using CLGeocoder (completion handler version)
    
    
    func fetchTimeZoneNative(for coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("❌ Reverse geocode failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placemark = placemarks?.first, let timeZone = placemark.timeZone {
                //print("🌍 Native timezone fetched: \(timeZone.identifier)")
                completion(timeZone.identifier)
            } else {
                print("❌ No timezone found from reverse geocode")
                completion(nil)
            }
        }
    }

    func convertUTCToLocalTime(utcDate: Date, timeZoneIdentifier: String) -> Date? {
        guard let tz = TimeZone(identifier: timeZoneIdentifier) else { return nil }
        let seconds = TimeInterval(tz.secondsFromGMT(for: utcDate))
        return utcDate.addingTimeInterval(seconds)
    }

    // Weather fetch using completion handler (original)
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at utcDate: Date, completion: @escaping (WeatherAnnotation?) -> Void) {

        fetchTimeZoneNative(for: coordinate) { timezoneIdentifier in
            guard let timezoneIdentifier = timezoneIdentifier else {
                print("❌ Failed to fetch timezone")
                completion(nil)
                return
            }
            
            // Use the UTC date directly. DateFormatter will apply the timezone.
            let timeZone = TimeZone(identifier: timezoneIdentifier)!
            
            // Prepare date string (yyyy-MM-dd) for API start/end date parameters
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = timeZone
            let dateString = dateFormatter.string(from: utcDate)
            
            // Prepare hour string (yyyy-MM-dd'T'HH:00) for matching hourly data
            let hourFormatter = DateFormatter()
            hourFormatter.dateFormat = "yyyy-MM-dd'T'HH:00"
            hourFormatter.timeZone = timeZone
            let hourString = hourFormatter.string(from: utcDate)
            
            // Build Open-Meteo API URL using timezone identifier as parameter
            let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&hourly=temperature_2m,windspeed_10m,winddirection_10m,relativehumidity_2m&timezone=\(timezoneIdentifier)&start_date=\(dateString)&end_date=\(dateString)"
            
            guard let url = URL(string: urlStr) else {
                print("❌ Invalid weather URL")
                completion(nil)
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    print("❌ Weather API network error: \(error?.localizedDescription ?? "Unknown")")
                    completion(nil)
                    return
                }
                
                if let rawString = String(data: data, encoding: .utf8) {
                    // Uncomment to debug raw API response
                    // print("🌐 Raw API Response:\n\(rawString)")
                }
                print("weather retrieved")
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let hourly = json?["hourly"] as? [String: Any],
                       let times = hourly["time"] as? [String],
                       let temps = hourly["temperature_2m"] as? [Double],
                       let hums = hourly["relativehumidity_2m"] as? [Double],
                       let windSpeeds = hourly["windspeed_10m"] as? [Double],
                       let windDirs = hourly["winddirection_10m"] as? [Double] {
                        
                        if let targetIndex = times.firstIndex(of: hourString) {
                            let temp = temps[targetIndex]
                            let hum = hums[targetIndex]
                            let windSpeed = windSpeeds[targetIndex]
                            let windDir = windDirs[targetIndex]
                            
                            let annotation = WeatherAnnotation(coordinate: coordinate, temperature: temp, humidity: hum, windSpeed: windSpeed, windDirection: windDir)
                            
                            DispatchQueue.main.async {
                                // Uncomment to debug weather annotation creation
                                 //print("✅ Weather annotation created: temp=\(temp) hum=\(hum) windSpeed=\(windSpeed) windDir=\(windDir)")
                                completion(annotation)
                            }
                            return
                        } else {
                            print("❌ No matching hour found for \(hourString)")
                        }
                    } else {
                        print("❌ Unexpected JSON structure from Open-Meteo")
                    }
                    
                    DispatchQueue.main.async { completion(nil) }
                    
                } catch {
                    print("❌ Weather API parsing error: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion(nil) }
                }
                
            }.resume()
        }
    }
}

// MARK: - Async/Await Extensions

extension WeatherDataProcessor {
    
    // Async version of timezone fetch
    func fetchTimeZoneNativeAsync(for coordinate: CLLocationCoordinate2D) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return try await withCheckedThrowingContinuation { continuation in
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let timeZone = placemarks?.first?.timeZone?.identifier {
                    //print("🌍 Native timezone fetched async: \(timeZone)")
                    continuation.resume(returning: timeZone)
                } else {
                    continuation.resume(throwing: NSError(domain: "WeatherDataProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "No timezone found"]))
                }
            }
        }
    }
    
    // Async version of weather fetch
    func fetchWeather(for coordinate: CLLocationCoordinate2D, at utcDate: Date) async throws -> WeatherAnnotation? {
        let timezoneIdentifier = try await fetchTimeZoneNativeAsync(for: coordinate)
        let timeZone = TimeZone(identifier: timezoneIdentifier)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = timeZone
        let dateString = dateFormatter.string(from: utcDate)

        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "yyyy-MM-dd'T'HH:00"
        hourFormatter.timeZone = timeZone
        let hourString = hourFormatter.string(from: utcDate)
        
        let urlStr = "https://api.open-meteo.com/v1/forecast?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&hourly=temperature_2m,windspeed_10m,winddirection_10m,relativehumidity_2m&timezone=\(timezoneIdentifier)&start_date=\(dateString)&end_date=\(dateString)"

        guard let url = URL(string: urlStr) else {
            print("❌ Invalid weather URL")
            return nil
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        if let rawString = String(data: data, encoding: .utf8) {
            // Uncomment to debug raw API response
            // print("🌐 Raw API Response:\n\(rawString)")
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let hourly = json?["hourly"] as? [String: Any],
               let times = hourly["time"] as? [String],
               let temps = hourly["temperature_2m"] as? [Double],
               let hums = hourly["relativehumidity_2m"] as? [Double],
               let windSpeeds = hourly["windspeed_10m"] as? [Double],
               let windDirs = hourly["winddirection_10m"] as? [Double] {

                if let targetIndex = times.firstIndex(of: hourString) {
                    let temp = temps[targetIndex]
                    let hum = hums[targetIndex]
                    let windSpeed = windSpeeds[targetIndex]
                    let windDir = windDirs[targetIndex]

                    return WeatherAnnotation(coordinate: coordinate, temperature: temp, humidity: hum, windSpeed: windSpeed, windDirection: windDir)
                } else {
                    print("❌ No matching hour found for \(hourString)")
                }
            } else {
                print("❌ Unexpected JSON structure from Open-Meteo")
            }
        } catch {
            print("❌ Weather API parsing error: \(error.localizedDescription)")
        }
        return nil
    }
}

// MARK: - OpenMeteo Models

struct OpenMeteoArchiveResponse: Codable {
    let hourly: OpenMeteoHourly
}

struct OpenMeteoHourly: Codable {
    let time: [String]
    let temperature_2m: [Double]
    let relativehumidity_2m: [Double]
    let windspeed_10m: [Double]
    let winddirection_10m: [Double]
}

// MARK: - WeatherAnnotation Model (assuming you have this somewhere)
/*
struct WeatherAnnotation {
    let coordinate: CLLocationCoordinate2D
    let temperature: Double
    let humidity: Double
    let windSpeed: Double
    let windDirection: Double
}
*/
