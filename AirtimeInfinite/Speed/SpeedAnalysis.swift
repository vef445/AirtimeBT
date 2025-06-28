//
//  SpeedAnalysis.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 27/06/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import Foundation

struct SpeedAnalysis {
    static func speedAccuracy(vAcc: Double) -> Double {
        return (sqrt(2) * vAcc) / 3.0
    }

    static func fastestAverageDescentSpeedInPerformanceWindow(
        data: [DataPoint],
        windowDuration: Double = 3.0
    ) async -> (
        startTime: Int,
        maxAvgDescentSpeedkmh: Double,
        maxAvgDescentSpeedmph: Double,
        performanceWindowStartAltitude: Double,
        performanceWindowEndAltitude: Double,
        validationWindowStartAltitude: Double,
        validationWindowEndAltitude: Double,
        averageSpeedAccuracy: Double,
        maxSpeedAccuracy: Double,
        speedAccuracyAlert: Bool,
        localGroundElevation: Double?,
        agl: Double?
    )? {
        guard !data.isEmpty else { return nil }

        let minTriggerDescentSpeed = 10.0 // m/s
        let maxAltitudeDrop = 2256.0 // m
        let targetMinAltitude = 1707.0 // m
        let validationWindowHeight = 1006.0 // m

        var performanceWindow: [DataPoint] = []

        var windowStartAltitude = 0.0
        var windowEndAltitude = 0.0

        // 1. Find the performance window
        var i = 0
        while i < data.count {
            let point = data[i]

            if point.velD >= minTriggerDescentSpeed {
                windowStartAltitude = point.altitude
                let startAltitude = point.altitude

                var j = i
                var lastValidPoint: DataPoint? = nil
                var crossingPoint: DataPoint? = nil

                while j < data.count {
                    let currentPoint = data[j]
                    let altitudeDrop = startAltitude - currentPoint.altitude

                    if currentPoint.altitude <= targetMinAltitude || altitudeDrop >= maxAltitudeDrop {
                        crossingPoint = currentPoint
                        break
                    }

                    performanceWindow.append(currentPoint)
                    lastValidPoint = currentPoint
                    j += 1
                }

                // Include crossing point
                if let crossing = crossingPoint {
                    performanceWindow.append(crossing)
                }

                // Set end altitude clipped to threshold
                if let crossing = crossingPoint {
                    if crossing.altitude <= targetMinAltitude {
                        windowEndAltitude = targetMinAltitude
                    } else {
                        windowEndAltitude = startAltitude - maxAltitudeDrop
                    }
                } else if let last = lastValidPoint {
                    windowEndAltitude = last.altitude
                } else {
                    windowEndAltitude = startAltitude
                }

                break
            }

            i += 1
        }

        if performanceWindow.isEmpty { return nil }

        // Round timestamps in performanceWindow to 0.01
        let roundedPerformanceWindow = performanceWindow.map { point -> DataPoint in
            var newPoint = point
            newPoint.secondsFromStart = (point.secondsFromStart * 100).rounded() / 100
            return newPoint
        }

        // Calculate validation window altitudes
        let validationWindowStartAltitude = windowEndAltitude + validationWindowHeight
        let validationWindowEndAltitude = windowEndAltitude

        // Filter data points in validation window altitude range (inclusive)
        let validationWindowPoints = data.filter { point in
            point.altitude >= validationWindowEndAltitude && point.altitude <= validationWindowStartAltitude
        }

        // Calculate speed accuracy values for validation window points
        let speedAccuracies = validationWindowPoints.map { speedAccuracy(vAcc: $0.vAcc) }

        let averageSpeedAccuracy = speedAccuracies.isEmpty ? 0.0 : speedAccuracies.reduce(0, +) / Double(speedAccuracies.count)
        let maxSpeedAccuracy = speedAccuracies.max() ?? 0.0
        let speedAccuracyAlert = maxSpeedAccuracy > 3.0

        // 2. Calculate fastest average descent speed within performance window using fixed sample interval sliding window
        let sampleInterval = 0.2 // seconds between data points (adjust if your actual interval differs)
        let windowPointsCount = Int(windowDuration / sampleInterval)

        guard windowPointsCount > 0, roundedPerformanceWindow.count >= windowPointsCount else {
            return nil
        }

        var maxAvgDescentSpeed = 0.0
        var maxStartTime = 0.0

        for startIndex in 0...(roundedPerformanceWindow.count - windowPointsCount) {
            let windowPoints = roundedPerformanceWindow[startIndex..<(startIndex + windowPointsCount)]
            let speeds = windowPoints.compactMap { $0.velD > 0 ? $0.velD : nil }
            if !speeds.isEmpty {
                let avgSpeed = speeds.reduce(0, +) / Double(speeds.count)
                if avgSpeed > maxAvgDescentSpeed {
                    maxAvgDescentSpeed = avgSpeed
                    maxStartTime = windowPoints.first!.secondsFromStart
                }
            }
        }
        
        // Fetch elevation data async
        let elevationResult = await getFastestDescentAGL(data: data)

        let localGroundElevation = elevationResult?.groundElevation
        let agl = elevationResult?.agl

        if maxAvgDescentSpeed > 0 {
            let kmh = maxAvgDescentSpeed * 3.6
            let mph = maxAvgDescentSpeed * 2.23694
            return (
                Int(round(maxStartTime)),
                kmh,
                mph,
                windowStartAltitude,
                windowEndAltitude,
                validationWindowStartAltitude,
                validationWindowEndAltitude,
                averageSpeedAccuracy,
                maxSpeedAccuracy,
                speedAccuracyAlert,
                localGroundElevation,
                agl
            )
        } else {
            return nil
        }
    }
}
