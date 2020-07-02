//
//  FlightMetric.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Flight metric attributes
enum FlightMetric { case time, hVel, vVel, tVel, alt, dive, glide, hDist
    
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
        }
    }
}
