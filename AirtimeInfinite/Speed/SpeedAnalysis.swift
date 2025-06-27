//
//  SpeedAnalysis.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 27/06/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import Foundation
    
    /// Finds the fastest average ground speed over a given time window (e.g. 3 seconds),
    /// only considering segments where altitudeAboveGround >= minAltitude for the entire window.
    ///
    /// - Parameters:
    ///   - data: Array of TrackPoint containing the track data.
    ///   - windowDuration: The duration over which to average speed, in seconds.
    ///   - minAltitude: The minimum altitude above ground required for all points in the window.
    ///
    /// - Returns: A tuple containing the start time of the fastest window and its average speed,
    ///            or nil if no valid window is found.
struct SpeedAnalysis {
    static func fastestAverageDescentSpeed(
        data: [DataPoint],
        windowDuration: Double,
        minAltitude: Double
    ) -> (startTime: Int, maxAvgDescentSpeedkmh: Double, maxAvgDescentSpeedmph: Double)? {

        guard !data.isEmpty else { return nil }

        var maxAvgDescentSpeed = 0.0
        var maxStartTime = 0.0

        var i = 0
        while i < data.count {
            let point = data[i]

            if point.altitude < minAltitude {
                i += 1
                continue
            }

            let windowStartTime = point.secondsFromStart
            let windowEndTime = windowStartTime + windowDuration

            var j = i
            var sumDescentSpeed = 0.0
            var count = 0
            var isValidWindow = true

            while j < data.count && data[j].secondsFromStart <= windowEndTime {
                let currentPoint = data[j]

                if currentPoint.altitude < minAltitude {
                    isValidWindow = false
                    break
                }

                if currentPoint.velD > 0 {
                    sumDescentSpeed += currentPoint.velD
                    count += 1
                }

                j += 1
            }

            if isValidWindow && count > 0 {
                let avgDescentSpeed = sumDescentSpeed / Double(count)
                if avgDescentSpeed > maxAvgDescentSpeed {
                    maxAvgDescentSpeed = avgDescentSpeed
                    maxStartTime = windowStartTime
                }
            }

            i += 1
        }

        if maxAvgDescentSpeed > 0 {
            let kmh = maxAvgDescentSpeed * 3.6
            let mph = maxAvgDescentSpeed * 2.23694
            return (Int(round(maxStartTime)), kmh, mph)
        } else {
            return nil
        }
    }
}
