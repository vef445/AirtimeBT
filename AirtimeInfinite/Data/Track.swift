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
    
    private var cachedGroundElevation: Double? = nil
    
    enum TrackError: Error {
        case noReadableTrackfileData
    }
    
    /// Private full data storage
    private var _fullTrackData = [DataPoint]()
    
    /// Backup for original uncut data (for restore)
    private var _originalFullTrackData: [DataPoint]? = nil
    
    /// Public filtered data: only from 5 seconds before exit until end
    var trackData: [DataPoint] {
        get {
            guard !_fullTrackData.isEmpty else { return [] }

            switch MainProcessor.instance.autoCutTrackOption {
            case .never:
                return _fullTrackData

            case .jump:
                var workingTrack = _fullTrackData

                // Cut before exit, like you had before
                if exitIndex.isValidIndex(in: workingTrack) {
                    let exitTime = workingTrack[exitIndex].secondsFromStart
                    let cutStartTime = max(0, exitTime - 5)
                    if let startIndex = workingTrack.firstIndex(where: { $0.secondsFromStart >= cutStartTime }) {
                        workingTrack = Array(workingTrack[startIndex...])
                    }
                }

                // Cut after landing
                if let landingIndex = calculateLandingPointIndex(in: workingTrack),
                   landingIndex.isValidIndex(in: workingTrack) {
                    let landingTime = workingTrack[landingIndex].secondsFromStart
                    let cutEndTime = landingTime + 2
                    if let endIndex = workingTrack.lastIndex(where: { $0.secondsFromStart <= cutEndTime }) {
                        workingTrack = Array(workingTrack[...endIndex])
                    }
                }

                return workingTrack

            case .swoop:  // if swoop start can not be found then fall back to cut on whole jump
                var workingTrack = _fullTrackData

                if let swoopStartIndex = calculateSwoopStartIndex(in: workingTrack),
                   swoopStartIndex.isValidIndex(in: workingTrack) {
                    let swoopStartTime = workingTrack[swoopStartIndex].secondsFromStart
                    let cutStartTime = max(0, swoopStartTime - 5)  // 5 seconds before swoop start, but not negative
                    if let startIndex = workingTrack.firstIndex(where: { $0.secondsFromStart >= cutStartTime }) {
                        workingTrack = Array(workingTrack[startIndex...])
                    }

                    if let landingIndex = calculateLandingPointIndex(in: workingTrack),
                       landingIndex.isValidIndex(in: workingTrack) {
                        let landingTime = workingTrack[landingIndex].secondsFromStart
                        let cutEndTime = landingTime + 2
                        if let endIndex = workingTrack.lastIndex(where: { $0.secondsFromStart <= cutEndTime }) {
                            workingTrack = Array(workingTrack[...endIndex])
                        }
                    }
                } else {
                    // swoopStart not found, fallback to jump logic:
                    if exitIndex.isValidIndex(in: workingTrack) {
                        let exitTime = workingTrack[exitIndex].secondsFromStart
                        let cutStartTime = max(0, exitTime - 5)
                        if let startIndex = workingTrack.firstIndex(where: { $0.secondsFromStart >= cutStartTime }) {
                            workingTrack = Array(workingTrack[startIndex...])
                        }
                    }

                    if let landingIndex = calculateLandingPointIndex(in: workingTrack),
                       landingIndex.isValidIndex(in: workingTrack) {
                        let landingTime = workingTrack[landingIndex].secondsFromStart
                        let cutEndTime = landingTime + 2
                        if let endIndex = workingTrack.lastIndex(where: { $0.secondsFromStart <= cutEndTime }) {
                            workingTrack = Array(workingTrack[...endIndex])
                        }
                    }
                }

                return workingTrack
            }
        }
        set {
            _fullTrackData = newValue
        }
    }

    //Store landing time so it can be used to filter out some data
    var landingTime: Double? {
        guard let landingIndex = calculateLandingPointIndex(in: trackData),
              landingIndex.isValidIndex(in: trackData) else {
            return nil
        }
        return trackData[landingIndex].secondsFromStart
    }

    
    /// All x values used in TrackData on Charts, cached to quickly update Map
    var xRange: [Double] = []
    
    /// Index of the point calculated as the jump exit
    var exitIndex: Int = 0
    
    /// Reset the ground elevation when needed so it will be calculated again when loading a Track
    func resetGroundElevationCache() {
        cachedGroundElevation = nil
    }
    
    /**
     Load a track given the URL of the local file
     */
    func importURL(url: URL) async throws {
        var rawTrackFileData = try String(contentsOf: url)
        
        // Remove FS2 header before processing, if exists
        if rawTrackFileData.starts(with: "$FLYS") {
            if let range = rawTrackFileData.range(of: "$COL,") {
                rawTrackFileData = String(rawTrackFileData[range.upperBound...])
            }
        }
        
        var tempTrackData = [DataPoint]()
        
        let reader = try CSVReader(string: rawTrackFileData, hasHeaderRow: true)
        let decoder = CSVRowDecoder()
        
        // Skip the unit row
        reader.next()
        // Skip an extra row for FS2
        if reader.headerRow![0] == "GNSS" {
            reader.next()
        }
        
        while reader.next() != nil {
            let row = try decoder.decode(DataPoint.self, from: reader)
            tempTrackData.append(row)
        }
        
        try await self.initialize(dataPoints: tempTrackData)
        
        self.xRange = self.trackData.map { $0.secondsFromStart }
    }
    
    /// Resets track data
    func clearTrack() {
        _fullTrackData = []
        cachedGroundElevation = nil
        _originalFullTrackData = nil
    }
    
    func calculateExitPointFromData() -> Int? {
        let minTriggerDescentSpeed = 10.0  // m/s, freefall start speed
        let checkStartOffset = 2.0          // seconds after exit to start check
        let checkEndOffset = 3.0            // seconds after exit to end check
        
        for (index, point) in _fullTrackData.enumerated() {
            if point.velD >= minTriggerDescentSpeed {
                let exitTime = point.secondsFromStart
                
                guard
                    let startIndex = _fullTrackData.firstIndex(where: { $0.secondsFromStart >= exitTime + checkStartOffset }),
                    let endIndex = _fullTrackData.firstIndex(where: { $0.secondsFromStart >= exitTime + checkEndOffset }),
                    endIndex.isValidIndex(in: _fullTrackData),
                    startIndex.isValidIndex(in: _fullTrackData)
                else {
                    continue // Can't perform check, skip candidate
                }
                
                let startVelD = _fullTrackData[startIndex].velD
                let endVelD = _fullTrackData[endIndex].velD
                
                if endVelD > startVelD {
                    // Vertical speed is increasing between exit+2s and exit+3s → valid exit
                    return index
                }
                // else vertical speed not increasing → keep looking
            }
        }
        
        return nil
    }

    
    /// Calculate landing point index on track that is already cut before exit point based on speed and altitude criteria
    func calculateLandingPointIndex(in track: [DataPoint]) -> Int? {
        let landingSpeedThreshold: Double = 5.0 / 3.6  // <5 km/h
        let landingAltitudeThreshold: Double = 20.0    // <20m AGL
        
        for (index, point) in track.enumerated() {
            let totalSpeed = (point.velN * point.velN + point.velE * point.velE + point.velD * point.velD).squareRoot()
            
            if totalSpeed < landingSpeedThreshold && point.altitude < landingAltitudeThreshold {
                return index
            }
        }
        return nil
    }
    
    func calculateSwoopStartIndex(in track: [DataPoint]) -> Int? {
        guard !track.isEmpty else {
            print("fulltrackdata is empty")
            return nil
        }
        
        // 1) Find last index where elevation is above 500m
        guard let lastAbove500Index = track.lastIndex(where: { $0.altitude > 500 }) else {
            print("Never reached above 500m")
            return nil
        }
        
        // Calculate and print time from start for this point
        guard !track.isEmpty else {
            print("Track slice is empty")
            return nil
        }
        
        // 2) Find last index where elevation is above 50m (must be after lastAbove500Index)
        guard let lastAbove50Index = Array(track.enumerated()).reversed().first(where: { (index, point) in
            point.altitude > 50 && index >= lastAbove500Index
        })?.offset else {
            print("Never reached above 50m after 500m")
            return nil
        }
        
        // Define search range: from lastAbove500Index up to lastAbove50Index inclusive
        let searchRange = lastAbove500Index...lastAbove50Index
        
        // 3) Find highest vertical speed index in the range
        guard let highestVertSpeedIndexInRange = track[searchRange]
            .enumerated()
            .max(by: { $0.element.velD < $1.element.velD })?.offset else {
            print("Highest vertical speed not found in elevation range")
            return nil
        }
        
        // Convert offset in slice to absolute index in full array
        let highestVertSpeedIndex = highestVertSpeedIndexInRange + lastAbove500Index
        
        let highestVertSpeedTime = track[highestVertSpeedIndex].secondsFromStart
        
        // 4) Calculate time window start (30 seconds before highest vertical speed)
        let timeWindowStart = highestVertSpeedTime - 30
        
        
        // 5) Filter altitude candidates to those within the last 30 seconds before highest vertical speed
        let timeFilteredCandidates = track.enumerated().filter { (idx, point) in
            //idx >= lastAbove500Index &&
            idx <= lastAbove50Index &&
            point.secondsFromStart >= timeWindowStart &&
            point.secondsFromStart <= highestVertSpeedTime
        }
        
        guard !timeFilteredCandidates.isEmpty else {
            print("No candidates found in altitude and time range")
            return nil
        }
        
        // 6) Find lowest vertical speed index among filtered candidates
        guard let lowestVertSpeedCandidate = timeFilteredCandidates.min(by: { $0.element.velD < $1.element.velD }) else {
            print("Lowest vertical speed not found among candidates")
            return nil
        }
        
        let lowestVertSpeedIndex = lowestVertSpeedCandidate.offset
        
        let lowestVertSpeedTime = track[lowestVertSpeedIndex].secondsFromStart
        
        // 7) Define target time 3 seconds before lowest vertical speed point
        let targetTime = lowestVertSpeedTime - 3
        
        // 8) Filter candidates that are before targetTime and between lastAbove500Index and highestVertSpeedIndex
        let finalCandidates = track.enumerated().filter { (idx, point) in
            //idx >= lastAbove500Index &&
            idx < highestVertSpeedIndex &&
            point.secondsFromStart <= targetTime
        }
        
        guard !finalCandidates.isEmpty else {
            print("No final candidates found before target time")
            return nil
        }
        
        // 9) Choose candidate closest in time to targetTime
        let swoopStartCandidate = finalCandidates.min(by: {
            abs($0.element.secondsFromStart - targetTime) < abs($1.element.secondsFromStart - targetTime)
        })
        //print("Swoop start found")
        return swoopStartCandidate?.offset
    }



    /**
     Given raw array of track data, process for reading/display
     */
    func initialize(dataPoints tempTrackData: [DataPoint]) async throws {
        if tempTrackData.isEmpty {
            throw TrackError.noReadableTrackfileData
        }
        
        self._fullTrackData = tempTrackData
        let startTimeString = _fullTrackData[0].time
        
        // Only call getFastestDescentAGL if ground elevation not cached
        if cachedGroundElevation == nil {
            guard let result = await getFastestDescentAGL(data: _fullTrackData) else {
                throw TrackError.noReadableTrackfileData
            }
            cachedGroundElevation = result.groundElevation
        }
        
        let groundElevation = cachedGroundElevation!
        
        for point in _fullTrackData {
            point.initializeValues()
            point.setTimeInSeconds(startEpochString: startTimeString)
            point.setRealAltitude(groundElevation: groundElevation)
        }
        initializeAcceleration()
        initializeExit()
        calculateDistanceWithStartOffset()
    }
    
    /// Calculate acceleration using moving average velocity slope
    func initializeAcceleration() {
        for i in 0..<_fullTrackData.count {
            let dp = _fullTrackData[i]
            let iMin = max(0, i - 3)
            let iMax = min(_fullTrackData.count - 1, i + 3)
            let timeDelta = _fullTrackData[iMax].secondsFromStart - _fullTrackData[iMin].secondsFromStart
            
            dp.accelN = (_fullTrackData[iMax].velN - _fullTrackData[iMin].velN) / timeDelta
            dp.accelE = (_fullTrackData[iMax].velE - _fullTrackData[iMin].velE) / timeDelta
            dp.accelVert = (_fullTrackData[iMax].velD - _fullTrackData[iMin].velD) / timeDelta
            
            let vh: Double = (dp.velN * dp.velN + dp.velE * dp.velE).squareRoot()
            dp.accelParallel = (dp.accelN * dp.velN + dp.accelE * dp.velE) / vh
            dp.accelPerp = (dp.accelE * dp.velN - dp.accelN * dp.velE) / vh
            dp.accelTotal = (dp.accelN * dp.accelN + dp.accelE * dp.accelE + dp.accelVert * dp.accelVert).squareRoot()
        }
    }
    
    /// Calculate exit point
    func initializeExit() {
        guard let exitIdx = calculateExitPointFromData() else {
            exitIndex = 0
            let exitTime = _fullTrackData.first?.secondsSinceEpoch ?? 0
            for point in _fullTrackData {
                point.setSecondsFromExit(exitEpochTime: exitTime)
            }
            return
        }
        
        exitIndex = exitIdx

        // Adjust exitIndex to be 1 second earlier if possible
        let desiredExitTime = _fullTrackData[exitIndex].secondsFromStart - 1.0 //remove 1sec as actual exit happened 1sec before reaching 10m/s
        if let earlierIndex = _fullTrackData.lastIndex(where: { $0.secondsFromStart <= desiredExitTime }) {
            exitIndex = earlierIndex
        }

        let exitTime = _fullTrackData[exitIndex].secondsSinceEpoch

        
        for point in _fullTrackData {
            point.setSecondsFromExit(exitEpochTime: exitTime)
        }
    }
    
    /// Calculate distance from exit position
    func calculateDistanceWithStartOffset() {
        var dist2D: Double = 0
        
        for i in 0..<_fullTrackData.count {
            let dp = _fullTrackData[i]
            if i > 0 {
                let dp1 = _fullTrackData[i - 1]
                let dpLocation = CLLocation(latitude: dp.coordinate.latitude, longitude: dp.coordinate.longitude)
                let dp1Location = CLLocation(latitude: dp1.coordinate.latitude, longitude: dp1.coordinate.longitude)
                dist2D += dp1Location.distance(from: dpLocation)
            }
            dp.distance2D = dist2D
        }
        
        let exitDistance = _fullTrackData[exitIndex].distance2D
        for i in 0..<_fullTrackData.count {
            _fullTrackData[i].distance2D -= exitDistance
        }
    }
    
    /// Get full coordinates list
    func getCoordinatesList() -> [CLLocationCoordinate2D] {
        return trackData.map { $0.coordinate }
    }
    
    /// Return track data within time bounds
    func getTrackCoordinatesFromSecondsBounds(firstIndex: Double, lastIndex: Double) -> [CLLocationCoordinate2D] {
        var minIndex = nearestIndexToTime(firstIndex)
        var maxIndex = nearestIndexToTime(lastIndex)
        if minIndex > maxIndex { swap(&minIndex, &maxIndex) }
        guard minIndex.isValidIndex(in: _fullTrackData), maxIndex.isValidIndex(in: trackData) else { return [] }
        return Array(trackData[minIndex...maxIndex]).map { $0.coordinate }
    }
    
    /// Get nearest index to time
    func nearestIndexToTime(_ timeInSeconds: Double) -> Int {
        var i = 0
        while i < xRange.count && xRange[i] < timeInSeconds {
            i += 1
        }
        return min(i, xRange.count - 1)
    }
    
    /// Safely get exit DataPoint from filtered data
    func exitDataPointInFilteredData() -> DataPoint? {
        guard !_fullTrackData.isEmpty, exitIndex.isValidIndex(in: _fullTrackData) else { return nil }
        let exitTime = _fullTrackData[exitIndex].secondsFromStart
        let startFilterTime = max(0, exitTime - 5)
        let filteredStartIndex = _fullTrackData.firstIndex(where: { $0.secondsFromStart >= startFilterTime }) ?? 0
        let relativeExitIndex = exitIndex - filteredStartIndex
        let filteredData = self.trackData
        guard relativeExitIndex >= 0, relativeExitIndex < filteredData.count else { return nil }
        return filteredData[relativeExitIndex]
    }
    
    // MARK: - Cutting & Restoring Methods
    
    /// Cuts the track to the specified start and end time range
    func cutToTimeRange(startTime: Double, endTime: Double) {
        guard startTime < endTime else { return }
        
        if _originalFullTrackData == nil {
            _originalFullTrackData = _fullTrackData
        }
        
        let cutData = _fullTrackData.filter { $0.secondsFromStart >= startTime && $0.secondsFromStart <= endTime }
        _fullTrackData = cutData
        xRange = _fullTrackData.map { $0.secondsFromStart }
    }
    
    /// Restores the track to its original uncut data
    func restoreOriginalTrack() {
        guard let originalData = _originalFullTrackData else { return }
        _fullTrackData = originalData
        xRange = _fullTrackData.map { $0.secondsFromStart }
        _originalFullTrackData = nil
    }
}


/// Helper extension
extension Int {
    func isValidIndex<T>(in array: [T]) -> Bool {
        return self >= 0 && self < array.count
    }
}


