//
//  Track.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import MapKit
import SwiftUI

import CSV

/// Imports, processes, and holds all data from a track.
class Track: ObservableObject {
    
    enum TrackError: Error {
        case noReadableTrackfileData
    }
    
    static let gravity: Double = 9.80665
    
    var trackData = [DataPoint]()
    
    /// All x values used in TrackData on Charts, cached to quickly update Map
    var xRange: [Double] = []
    
    /// Inde of the point calculated as the jump exit
    var exitIndex: Int = 0
    
    /**
     Load a track given the URL of the local file
     
     - Parameter url:File URL for selected track
     
     - Throws: TrackError.noReadableTrackfileData  or access error if file cannot be accessed or parsed
     */
    func importURL(url: URL) throws {
        let rawTrackFileData = try String(contentsOf: url)
        var tempTrackData = [DataPoint]()
        
        let reader = try CSVReader(string: rawTrackFileData, hasHeaderRow: true)
        let decoder = CSVRowDecoder()
        reader.next()
        while reader.next() != nil {
            let row = try decoder.decode(DataPoint.self, from: reader)
            tempTrackData.append(row)
        }
        
        try self.initialize(dataPoints: tempTrackData)
        
        self.xRange = self.trackData.map { $0.secondsFromStart }
    }
    
    /// Resets track data
    func clearTrack() {
        trackData = []
    }
    
    /**
     Given a raw array of track data, load and process the track for reading/display
     
     - Parameters:
        - tempTrackData: Raw array of DataPoints
     
     - Throws: TrackError.noReadableTrackfileData  if there is no data to load
     */
    func initialize(dataPoints tempTrackData: [DataPoint]) throws {
        
        if tempTrackData.isEmpty {
            throw TrackError.noReadableTrackfileData
        }
        
        /// Only when we are sure there is data to load, overwrite the current data
        self.trackData = tempTrackData
        
        let startTimeString = trackData[0].time
        
        var groundElevation: Double = 0.0
        
        /// Lowest point on track, consider changng to last altitude
        if let lowestElevation = trackData.map({ $0.hMSL }).min() {
            groundElevation = lowestElevation
        }
        
        for point in trackData {
            point.initializeValues()
            point.setTimeInSeconds(startEpochString: startTimeString)
            point.setRealAltitude(groundElevation: groundElevation)
        }
        initializeAcceleration()
        initializeExit()
        calculateDistanceWithStartOffset()
    }
    
    /// Calculate acceleration for all points using a moving average velocity slope
    func initializeAcceleration() {
        for i in 0..<trackData.count {
            
            let dp = trackData[i]
            
            let iMin = max(0, i - 3)
            let iMax = min(trackData.count - 1, i + 3)
            
            let timeDelta = trackData[iMax].secondsFromStart - trackData[iMin].secondsFromStart
            
            /// Acceleration
            dp.accelN = (trackData[iMax].velN - trackData[iMin].velN) / timeDelta
            dp.accelE = (trackData[iMax].velE - trackData[iMin].velE) / timeDelta
            dp.accelVert = (trackData[iMax].velD - trackData[iMin].velD) / timeDelta
            
            /// Calculate acceleration in direction of flight
            let vh: Double = (dp.velN * dp.velN + dp.velE * dp.velE).squareRoot()
            dp.accelParallel = (dp.accelN * dp.velN + dp.accelE * dp.velE) / vh
            
            /// Calculate acceleration perpendicular to flight
            dp.accelPerp = (dp.accelE * dp.velN - dp.accelN * dp.velE) / vh
            
            /// Calculate total acceleration
            dp.accelTotal = (dp.accelN * dp.accelN + dp.accelE * dp.accelE + dp.accelVert * dp.accelVert).squareRoot()
        }
    }
    
    // TODO: Take another pass at this. The exit calc is ever so slightly off.
    /// Caculate the exit from plane or object
    func initializeExit() {
        var exitTime: Double = 0
        
        var foundExit: Bool = false
        
        for i in 1..<trackData.count {
            let dp1: DataPoint = trackData[i - 1]
            let dp2: DataPoint = trackData[i]
            
            /// Get interpolation coefficient
            let a = (Self.gravity - dp1.velD) / (dp2.velD - dp1.velD)
            
            /// Check vertical speed
            if a < 0 || 1 < a { continue }
            
            /// Check accuracy
            let vAcc = dp1.vAcc + a * (dp2.vAcc - dp1.vAcc);
            guard vAcc <= 10 else { continue }
            
            /// Check acceleration
            let az: Double = dp1.accelVert + a * (dp2.accelVert - dp1.accelVert);
            guard az >= Self.gravity / 5 else { continue }
            
            /// Determine exit
            let t1 = dp1.secondsSinceEpoch
            let t2 = dp2.secondsSinceEpoch
            exitTime = t1 + a * (t2 - t1) - Self.gravity / az
            exitIndex = i
            foundExit = true
            break
        }
        if !foundExit {
            exitTime = trackData[0].secondsSinceEpoch
        }
        
        /// Set time from exit for all points
        for point in trackData {
            point.setSecondsFromExit(exitEpochTime: exitTime)
        }
    }
    
    // TODO: Consider adding straight-line distance for better BASE exit stats
    /// Calculate the total distance traveled at all points from the exit position
    func calculateDistanceWithStartOffset() {
        
        var dist2D: Double = 0
        
        for i in 0..<trackData.count {
            let dp = trackData[i]
            
            if i > 0
            {
                let dp1 = trackData[i - 1]
                
                let dpLocation = CLLocation(
                    latitude: dp.coordinate.latitude,
                    longitude: dp.coordinate.longitude)
                let dp1Location = CLLocation(
                    latitude: dp1.coordinate.latitude,
                    longitude: dp1.coordinate.longitude)
                
                dist2D += dp1Location.distance(from: dpLocation)
            }
            
            dp.distance2D = dist2D
        }
        
        /// Offset with exit
        let exitDistance = trackData[exitIndex].distance2D
        for i in 0..<trackData.count {
            trackData[i].distance2D -= exitDistance
        }
        
        
    }
    
    /**
     Get a list of coordinates from the track
     
     - Returns: An arrray of CLLocationCoordinate2D objects
     */
    func getCoordinatesList() -> [CLLocationCoordinate2D] {
        
        var coordiatesList: [CLLocationCoordinate2D] = []
        for point in trackData {
            coordiatesList.append(point.coordinate)
        }
        return coordiatesList
    }
    
    /**
     Given a min and max time bound, return track data that falls within
     
     - Parameters:
        - firstIndex: Start time in seconds
        - lastIndex: Ending time in seconds
     
     - Returns: A track data array within the selected time bounds
     */
    func getTrackCoordinatesFromSecondsBounds(firstIndex: Double, lastIndex: Double) -> [CLLocationCoordinate2D] {
        var minIndex = nearestIndexToTime(firstIndex)
        var maxIndex = nearestIndexToTime(lastIndex)
        /// Protect against reverse order ranges
        if minIndex > maxIndex {
            let t = minIndex
            minIndex = maxIndex
            maxIndex = t
        }
        var selectedTrackCoordiantes: [CLLocationCoordinate2D] = []
        let validIndices = trackData.indices
        if validIndices.contains(minIndex), validIndices.contains(maxIndex){
            selectedTrackCoordiantes = Array(trackData[minIndex...maxIndex]).map({ $0.coordinate })
        }
        return selectedTrackCoordiantes
    }
    
    /**
     Given a time in seconds, get the index of the nearest DataPoint
     
     - Parameters:
        - timeInSeconds: Time from start of track
     
     - Returns: Index of closest DataPoint
     */
    func nearestIndexToTime(_ timeInSeconds: Double) -> Int {
        var i = 0
        while xRange[i] < timeInSeconds {
            i += 1
        }
        return i
    }
    
}
