//
//  FlightMetric.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Flight metric attributes
enum FlightMetric { case time, hVel, vVel, tVel, alt, dive, glide, hDist,
                         accelVertical, accelParallel, accelPerp, accelTotal
    
    /// Label used in small windows / abbreviations
    var shortLabel: String {
        switch self {
        case .time: return "Time"
        case .hVel: return "hVel"
        case .vVel: return "vVel"
        case .tVel: return "tVel"
        case .alt: return "Altitude"
        case .dive: return "Dive"
        case .glide: return "Glide"
        case .hDist: return "hDist"
        case .accelVertical: return "accV"
        case .accelParallel: return "accH"
        case .accelPerp: return "accPerp"
        case .accelTotal: return "accT"
        }
    }
    
    /// Full label
    var title: String {
        switch self {
        case .time: return "Time"
        case .hVel: return "Horizontal Speed"
        case .vVel: return "Vertical Speed"
        case .tVel: return "Total Speed"
        case .alt: return "Altitude"
        case .dive: return "Dive Angle"
        case .glide: return "Glide Ratio"
        case .hDist: return "Horizontal Distance"
        case .accelVertical: return "Vertical Acceleration"
        case .accelParallel: return "Parallel Acceleration"
        case .accelPerp: return "Perpendicular Acceleration"
        case .accelTotal: return "Total Acceleration"
        }
    }
    
    /// Unit of measurement
    var imperialUnit: String {
        switch self {
        case .time: return "sec"
        case .hVel: return "mph"
        case .vVel: return "mph"
        case .tVel: return "mph"
        case .alt: return "ft"
        case .dive: return "deg"
        case .glide: return "h/v"
        case .hDist: return "ft"
        case .accelVertical: return "ft/s/s"
        case .accelParallel: return "ft/s/s"
        case .accelPerp: return "ft/s/s"
        case .accelTotal: return "ft/s/s"
        }
    }
    
    var metricUnit: String {
        switch self {
        case .time: return "sec"
        case .hVel: return "km/h"
        case .vVel: return "km/h"
        case .tVel: return "km/h"
        case .alt: return "m"
        case .dive: return "deg"
        case .glide: return "h/v"
        case .hDist: return "m"
        case .accelVertical: return "ft/s/s"
        case .accelParallel: return "ft/s/s"
        case .accelPerp: return "ft/s/s"
        case .accelTotal: return "ft/s/s"
        }
    }
    
    /// Representation color
    var color: UIColor {
        switch self {
        case .time: return .label
        case .hVel: return .systemRed
        case .vVel: return .systemGreen
        case .tVel: return .systemBlue
        case .alt: return .systemGray
        case .dive: return .systemPink
        case .glide: return .cyan
        case .hDist: return .label
        case .accelVertical: return .systemPurple
        case .accelParallel: return .systemOrange
        case .accelPerp: return .systemTeal
        case .accelTotal: return .systemBrown
        }
    }
    
    /// Is this metric bound to the right axis of charts
    var rightAxis: Bool {
        switch self {
        case .time: return false
        case .hVel: return true
        case .vVel: return true
        case .tVel: return true
        case .alt: return false
        case .dive: return true
        case .glide: return true
        case .hDist: return false
        case .accelVertical: return true
        case .accelParallel: return true
        case .accelPerp: return true
        case .accelTotal: return true
        }
    }
    
    /// Do we display this by default to the user on charts
    var defaultVisible: Bool {
        switch self {
        case .time: return true
        case .hVel: return true
        case .vVel: return true
        case .tVel: return false
        case .alt: return true
        case .dive: return false
        case .glide: return false
        case .hDist: return false
        case .accelVertical: return false
        case .accelParallel: return false
        case .accelPerp: return false
        case .accelTotal: return false
        }
    }
}
