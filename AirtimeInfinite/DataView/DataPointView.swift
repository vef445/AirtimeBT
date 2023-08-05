//
//  DataPointView.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Displays raw stats for a number of metrics (e.g. altitude, speed, etc.) at a user selected point on the chart
struct DataPointView: View {

    @EnvironmentObject var main: MainProcessor
    var isMultiRow: Bool
    var showAcceleration: Bool
    
    let multiRow1 = [FlightMetric.time,
                     FlightMetric.hVel,
                     FlightMetric.vVel,
                     FlightMetric.tVel]
    
    let multiRow2 = [FlightMetric.alt,
                     FlightMetric.dive,
                     FlightMetric.glide,
                     FlightMetric.hDist]
    
    let accelRow = [FlightMetric.accelVertical,
                    FlightMetric.accelParallel,
                    FlightMetric.accelPerp,
                    FlightMetric.accelTotal
                    ]
    
    /// Reorder for single view to keep altitude on the left
    let singleRow = [FlightMetric.time,
                     FlightMetric.alt,
                     FlightMetric.hVel,
                     FlightMetric.vVel,
                     FlightMetric.tVel,
                     FlightMetric.dive,
                     FlightMetric.glide,
                     FlightMetric.hDist]
    
    var body: some View {
        Group{
            if isMultiRow {
                VStack {
                    DataPointRow(flightStats: multiRow1).frame(height: 40)
                    Divider().frame(height: 5)
                    DataPointRow(flightStats: multiRow2).frame(height: 40)
                }
            } else {
                HStack {
                    DataPointRow(flightStats: singleRow).frame(height: 40)
                }
            }
            if showAcceleration {
                HStack {
                    DataPointRow(flightStats: accelRow).frame(height: 40)
                }
            }
        }
    }
    
    mutating func updateOrientation(isVertical:Bool){
        self.isMultiRow = isVertical
    }
}

struct DataPointRow: View {
    
    let flightStats: [FlightMetric]
    
    var body: some View {
        HStack(alignment: .center) {
            Divider()
            ForEach(flightStats, id: \.self) { stat in
                HStack() {
                    DataPointCell(stat: stat)
                    Divider()
                }
            }
        }
    }
}

/// View holding a single stat at a selected datapoint
struct DataPointCell: View {
    
    var stat: FlightMetric
    @EnvironmentObject var main: MainProcessor
    
    /// Get the actual value at a given time vs in enum, done this way to handle observable objects
    var highlightedValue: Double? {
        switch stat {
        case .time: return main.highlightedPoint.point?.secondsFromExit
        case .hVel: return main.useImperialUnits ?
            main.highlightedPoint.point?.horizontalSpeed.metersPerSecondToMPH :
            main.highlightedPoint.point?.horizontalSpeed.metersPerSecondToKMH
        case .vVel: return main.useImperialUnits ?
            main.highlightedPoint.point?.velD.metersPerSecondToMPH :
            main.highlightedPoint.point?.velD.metersPerSecondToKMH
        case .tVel: return main.useImperialUnits ?
            main.highlightedPoint.point?.totalSpeed.metersPerSecondToMPH :
            main.highlightedPoint.point?.totalSpeed.metersPerSecondToKMH
        case .alt: return main.useImperialUnits ?
            main.highlightedPoint.point?.altitude.metersToFeet :
            main.highlightedPoint.point?.altitude
        case .glide: return main.highlightedPoint.point?.glideRatio
        case .dive: return main.highlightedPoint.point?.diveAngle
        case .hDist: return main.useImperialUnits ?
            main.highlightedPoint.point?.distance2D.metersToFeet :
            main.highlightedPoint.point?.distance2D
        case .accelVertical: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelVert.metersToFeet :
            main.highlightedPoint.point?.accelVert
        case .accelParallel: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelParallel.metersToFeet :
            main.highlightedPoint.point?.accelParallel
        case .accelPerp: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelPerp.metersToFeet :
            main.highlightedPoint.point?.accelPerp
        case .accelTotal: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelTotal.metersToFeet :
            main.highlightedPoint.point?.accelTotal
        }
    }
    
    var measurementBaseValue: Double? {
        switch stat {
        case .time: return main.selectedMeasurePoint.point?.secondsFromExit
        case .hVel: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.horizontalSpeed.metersPerSecondToMPH :
            main.selectedMeasurePoint.point?.horizontalSpeed.metersPerSecondToKMH
        case .vVel: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.velD.metersPerSecondToMPH :
            main.selectedMeasurePoint.point?.velD.metersPerSecondToKMH
        case .tVel: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.totalSpeed.metersPerSecondToMPH :
            main.selectedMeasurePoint.point?.totalSpeed.metersPerSecondToKMH
        case .alt: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.altitude.metersToFeet :
            main.selectedMeasurePoint.point?.altitude
        case .glide: return main.selectedMeasurePoint.point?.glideRatio
        case .dive: return main.selectedMeasurePoint.point?.diveAngle
        case .hDist: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.distance2D.metersToFeet :
            main.selectedMeasurePoint.point?.distance2D
        case .accelVertical: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelVert.metersToFeet :
            main.highlightedPoint.point?.accelVert
        case .accelParallel: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelParallel.metersToFeet :
            main.highlightedPoint.point?.accelParallel
        case .accelPerp: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelPerp.metersToFeet :
            main.highlightedPoint.point?.accelPerp
        case .accelTotal: return main.useImperialUnits ?
            main.highlightedPoint.point?.accelTotal.metersToFeet :
            main.highlightedPoint.point?.accelTotal
        }
    }
    
    var body: some View {
        GeometryReader { g in
            VStack {
                Text("\(self.stat.shortLabel) (\(self.main.useImperialUnits ? self.stat.imperialUnit : self.stat.metricUnit))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                /// If we are measuring from a value, display the delta to highlighted, otherwise just display highlighted
                Text("\(self.main.selectedMeasurePoint.isActive ? (self.highlightedValue ?? 0) - (self.measurementBaseValue ?? 0) : (self.highlightedValue ?? 0), specifier: "%.2f")")
                    .foregroundColor(Color(self.stat.color))
                    /// Guessing font size based on space avail
                    .font(.system(size: g.size.height / 4 + 10))
                    .lineLimit(1)
                    .allowsTightening(true)
                    .minimumScaleFactor(0.4)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
    }
}
