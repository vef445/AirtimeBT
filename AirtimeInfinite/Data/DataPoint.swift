//
//  DataPoint.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import MapKit
import SwiftUI

/// Model for a single data point within a track
class DataPoint: NSObject, Decodable, MKAnnotation, ObservableObject {

    
    /// CSV Track File Vars
    let GNSS: Optional<String>
    let time: String
    let lat: Double
    let lon: Double
    let hMSL: Double
    let velN: Double
    let velE: Double
    let velD: Double
    let hAcc: Double
    let vAcc: Double
    let sAcc: Double
    let heading: Optional<Double>
    let cAcc: Optional<Double>
    let gpsFix: Optional<Int>
    let numSV: Int
    
    /// These need to be lazy to not be expected by the CSV decoder, could likely use optional instead
    lazy var secondsSinceEpoch: Double = 0
    lazy var secondsFromStart: Double = 0
    lazy var secondsFromExit: Double = 0
    
    lazy var altitude: Double = 0
    
    lazy var coordinate = CLLocationCoordinate2DMake(0, 0)
    
    lazy var horizontalSpeed: Double = 0
    lazy var totalSpeed: Double = 0
    
    lazy var glideRatio: Double = 0
    lazy var diveAngle: Double = 0
    
    lazy var accelN: Double = 0
    lazy var accelE: Double = 0
    lazy var accelParallel: Double = 0
    lazy var accelPerp: Double = 0
    lazy var accelVert: Double = 0
    lazy var accelTotal: Double = 0
    
    lazy var distance2D: Double = 0
    
    init(
        GNSS: String?,
        time: String,
        lat: Double,
        lon: Double,
        hMSL: Double,
        velN: Double,
        velE: Double,
        velD: Double,
        hAcc: Double,
        vAcc: Double,
        sAcc: Double,
        heading: Double?,
        cAcc: Double?,
        gpsFix: Int?,
        numSV: Int
    ) {
        self.GNSS = GNSS
        self.time = time
        self.lat = lat
        self.lon = lon
        self.hMSL = hMSL
        self.velN = velN
        self.velE = velE
        self.velD = velD
        self.hAcc = hAcc
        self.vAcc = vAcc
        self.sAcc = sAcc
        self.heading = heading
        self.cAcc = cAcc
        self.gpsFix = gpsFix
        self.numSV = numSV
    }

    
    /**
     Converts a FlySight time string into a Swift Date object
     
     - Parameters:
        - time: Time string in the format yyyy-MM-dd'T'HH:mm:ss.SSS'Z'
     
     - Returns: Date object representing the string time
     */
    static func parseTime(time: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        if let date = dateFormatter.date(from: time) {
            return date
        } else { return Date() }
    }
    
    /// Converts time string to a seconds since epoch value
    func setSecondsSinceEpoch() {
        secondsSinceEpoch = DataPoint.parseTime(time: self.time).timeIntervalSince1970
    }
    
    /**
     Sets time in seconds with a base of the start of the track file
     
     - Parameters:
        - startEpochString: Time string in the format yyyy-MM-dd'T'HH:mm:ss.SSS'Z'
     */
    func setTimeInSeconds(startEpochString: String) {
        let startEpochSeconds = DataPoint.parseTime(time: startEpochString).timeIntervalSince1970
        self.secondsFromStart = secondsSinceEpoch - startEpochSeconds
    }
    
    /**
     Sets time in seconds with a base of the time of exit
     
     - Parameters:
        - exitEpochTime:Time of exit in seconds since epoch
     */
    func setSecondsFromExit(exitEpochTime: Double) {
        self.secondsFromExit = secondsSinceEpoch - exitEpochTime
    }
    
    /**
     Sets AGL elevation based on a ground elevation offset
     
     - Parameters:
     - groundElevation:height of ground elevation in meters
     */
    func setRealAltitude(groundElevation: Double) {
        self.altitude = self.hMSL - groundElevation
    }
    
    /// Create a CLLocationCoordinate with the lat and lon values
    func generateCoordiantes() {
        self.coordinate = CLLocationCoordinate2DMake(lat, lon)
    }
    
    /// Use North and East speed to calculate horizontal speed
    func calcHorizontalSpeed() {
        horizontalSpeed = ((velN * velN) + (velE * velE)).squareRoot()
    }
    
    /// Use Nort, East, and  vertical speeds to calculate total speed
    func calcTotalSpeed() {
        totalSpeed = ((velN * velN) + (velE * velE) + (velD * velD)).squareRoot()
    }
    
    /// Calculate glide ratio given horizontal and vertical speeds
    func calcGlideRatio() {
        if velD != 0 {
            glideRatio  = horizontalSpeed / velD
        } else {
            glideRatio = 0
        }
    }
    
    /// Callculate dive angle at point
    func calcDiveAngle() {
        diveAngle = atan2(velD, horizontalSpeed) / Double.pi * 180;
        
    }
    
    /// Use avilable data within the point to initialize complex metrics (Coordinates, speeds, glide, dive, etc.)
    func initializeValues() {
        setSecondsSinceEpoch()
        generateCoordiantes()
        calcHorizontalSpeed()
        calcTotalSpeed()
        calcGlideRatio()
        calcDiveAngle()
    }
}
extension DataPoint {
    func copy() -> DataPoint {
        let copy = DataPoint(
            GNSS: self.GNSS,
            time: self.time,
            lat: self.lat,
            lon: self.lon,
            hMSL: self.hMSL,
            velN: self.velN,
            velE: self.velE,
            velD: self.velD,
            hAcc: self.hAcc,
            vAcc: self.vAcc,
            sAcc: self.sAcc,
            heading: self.heading,
            cAcc: self.cAcc,
            gpsFix: self.gpsFix,
            numSV: self.numSV
        )
        
        // Copy all the lazy properties
        copy.secondsSinceEpoch = self.secondsSinceEpoch
        copy.secondsFromStart = self.secondsFromStart
        copy.secondsFromExit = self.secondsFromExit
        copy.altitude = self.altitude
        copy.coordinate = self.coordinate
        copy.horizontalSpeed = self.horizontalSpeed
        copy.totalSpeed = self.totalSpeed
        copy.glideRatio = self.glideRatio
        copy.diveAngle = self.diveAngle
        copy.accelN = self.accelN
        copy.accelE = self.accelE
        copy.accelParallel = self.accelParallel
        copy.accelPerp = self.accelPerp
        copy.accelVert = self.accelVert
        copy.accelTotal = self.accelTotal
        copy.distance2D = self.distance2D
        
        return copy
    }
}

