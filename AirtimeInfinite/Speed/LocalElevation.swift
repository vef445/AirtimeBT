//
//  LocalElevation.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 28/06/2025.
//
import Foundation

/// Fetches ground elevation from Open-Elevation API for given latitude and longitude.
/// Returns elevation in meters or nil if fetch fails.
func fetchGroundElevation(lat: Double, lon: Double) async -> Double? {
    let urlString = "https://api.open-elevation.com/api/v1/lookup?locations=\(lat),\(lon)"
    guard let url = URL(string: urlString) else { return nil }

    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = json["results"] as? [[String: Any]],
           let elevation = results.first?["elevation"] as? Double {
            //print("Retrieved elevation: \(elevation)")
            return elevation
        }
    } catch {
        print("Error fetching elevation: \(error)")
    }

    return nil
}

/// Finds the point with the fastest descent (max velD) in your DataPoint array.
func findFastestDescentPoint(in dataPoints: [DataPoint]) -> DataPoint? {
    return dataPoints.max(by: { $0.velD < $1.velD })
}

/// Finds the lowest altitude (hMSL) among data points.
/// Returns nil if the array is empty.
func findLowestAltitude(in dataPoints: [DataPoint]) -> Double? {
    return dataPoints.min(by: { $0.hMSL < $1.hMSL })?.hMSL
}

/// Retrieves the ground elevation at the fastest descent point location,
/// and calculates AGL for that point.
/// Returns tuple (agl, groundElevation, DataPoint) or nil on failure.
func getFastestDescentAGL(data: [DataPoint]) async -> (agl: Double, groundElevation: Double, point: DataPoint)? {
    guard let fastestDescentPoint = findFastestDescentPoint(in: data) else {
        print("No data points found.")
        return nil
    }

    var groundElevation: Double?

    // Try fetching online elevation first
    //groundElevation = await fetchGroundElevation(lat: fastestDescentPoint.lat,
    //                                             lon: fastestDescentPoint.lon)
    groundElevation = nil  //Avoid retrieving local elevation via API as this is too unprecise. Using lowest altitude instead

    // Fallback to lowest measured altitude if no internet or API fails
    if groundElevation == nil {
        if let lowestAltitude = findLowestAltitude(in: data) {
            print("Using lowest measured altitude as ground elevation fallback: \(lowestAltitude)")
            groundElevation = lowestAltitude
        } else {
            print("Failed to retrieve ground elevation and no fallback available.")
            return nil
        }
    }

    let agl = fastestDescentPoint.hMSL - (groundElevation ?? 0)
    return (agl, groundElevation ?? 0, fastestDescentPoint)
}
