//
//  DataPointView.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Displays raw stats for a number of metrics (e.g. altitude, speed, etc.) at a user selected point on the chart
struct DataPointView: View {

    @EnvironmentObject var main: MainProcessor
    @Binding var showValues: Bool
    
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
            Group {
                if isMultiRow {
                    VStack(spacing: 1) {
                        DataPointRow(flightStats: multiRow1, showValues: $showValues)
                            .frame(height: 40)
                        Divider()
                        DataPointRow(flightStats: multiRow2, showValues: $showValues)
                            .frame(height: 40)
                    }
                    .padding(.bottom, -20)
                } else {
                    HStack {
                        DataPointRow(flightStats: singleRow, showValues: $showValues)
                            .frame(height: 40)
                    }
                }
                if showAcceleration {
                    VStack {
                        Divider()
                        DataPointRow(flightStats: accelRow, showValues: $showValues)
                            .frame(height: 40)
                    }
                }
            }
            .contentShape(Rectangle()) // Make whole area tappable / gesture sensitive
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if showValues {  // only update if needed, to avoid repeated sets
                            showValues = false  // show units on press down
                        }
                    }
                    .onEnded { _ in
                        showValues = true   // show values again on release
                    }
            )
        }
    }

struct DataPointRow: View {
    let flightStats: [FlightMetric]
    @Binding var showValues: Bool
    
    var body: some View {
        HStack(alignment: .center) {
            Divider()
            ForEach(flightStats, id: \.self) { stat in
                HStack {
                    DataPointCell(stat: stat, showValue: $showValues)
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
    @Binding var showValue: Bool

    // Using UnitsManager to get the unit string
    var unitString: String {
        switch stat {
        case .hVel, .vVel, .tVel:
            return UnitsManager.retrieveUserUnit(
                for: .speed,
                preference: main.unitPreference,
                customAltitudeUnit: main.customAltitudeUnit,
                customSpeedUnit: main.customSpeedUnit,
                customDistanceUnit: main.customDistanceUnit
            )
        case .alt:
            return UnitsManager.retrieveUserUnit(
                for: .altitude,
                preference: main.unitPreference,
                customAltitudeUnit: main.customAltitudeUnit,
                customSpeedUnit: main.customSpeedUnit,
                customDistanceUnit: main.customDistanceUnit
            )
        case .hDist, .accelVertical, .accelParallel, .accelPerp, .accelTotal:
            return UnitsManager.retrieveUserUnit(
                for: .distance,
                preference: main.unitPreference,
                customAltitudeUnit: main.customAltitudeUnit,
                customSpeedUnit: main.customSpeedUnit,
                customDistanceUnit: main.customDistanceUnit
            )
        case .time:
            return "sec"
        case .glide:
            return "h/v"
        case .dive:
            return "deg"
        }
    }

    // Conversion function that applies the proper factor
    func convertValue(_ value: Double?, for stat: FlightMetric) -> Double? {
            guard let val = value else { return nil }
            
            switch stat {
            case .hVel, .vVel, .tVel:
                let factor = UnitsManager.conversionFactor(
                    for: .speed,
                    preference: main.unitPreference,
                    customAltitudeUnit: main.customAltitudeUnit,
                    customSpeedUnit: main.customSpeedUnit,
                    customDistanceUnit: main.customDistanceUnit
                )
                return val * factor
                
            case .alt:
                let factor = UnitsManager.conversionFactor(
                    for: .altitude,
                    preference: main.unitPreference,
                    customAltitudeUnit: main.customAltitudeUnit,
                    customSpeedUnit: main.customSpeedUnit,
                    customDistanceUnit: main.customDistanceUnit
                )
                return val * factor
                
            case .hDist, .accelVertical, .accelParallel, .accelPerp, .accelTotal:
                let factor = UnitsManager.conversionFactor(
                    for: .distance,
                    preference: main.unitPreference,
                    customAltitudeUnit: main.customAltitudeUnit,
                    customSpeedUnit: main.customSpeedUnit,
                    customDistanceUnit: main.customDistanceUnit
                )
                return val * factor
                
            default:
                return val
            }
        }

    var highlightedValue: Double? {
        switch stat {
        case .time: return main.highlightedPoint.point?.secondsFromExit
        case .hVel: return convertValue(main.highlightedPoint.point?.horizontalSpeed.metersPerSecondToKMH, for: .hVel)
        case .vVel: return convertValue(main.highlightedPoint.point?.velD.metersPerSecondToKMH, for: .vVel)
        case .tVel: return convertValue(main.highlightedPoint.point?.totalSpeed.metersPerSecondToKMH, for: .tVel)
        case .alt: return convertValue(main.highlightedPoint.point?.altitude, for: .alt)
        case .glide: return main.highlightedPoint.point?.glideRatio
        case .dive: return main.highlightedPoint.point?.diveAngle
        case .hDist: return convertValue(main.highlightedPoint.point?.distance2D, for: .hDist)
        case .accelVertical: return convertValue(main.highlightedPoint.point?.accelVert, for: .accelVertical)
        case .accelParallel: return convertValue(main.highlightedPoint.point?.accelParallel, for: .accelParallel)
        case .accelPerp: return convertValue(main.highlightedPoint.point?.accelPerp, for: .accelPerp)
        case .accelTotal: return convertValue(main.highlightedPoint.point?.accelTotal, for: .accelTotal)
        }
    }

    var measurementBaseValue: Double? {
        switch stat {
        case .time: return main.selectedMeasurePoint.point?.secondsFromExit
        case .hVel: return convertValue(main.selectedMeasurePoint.point?.horizontalSpeed.metersPerSecondToKMH, for: .hVel)
        case .vVel: return convertValue(main.selectedMeasurePoint.point?.velD.metersPerSecondToKMH, for: .vVel)
        case .tVel: return convertValue(main.selectedMeasurePoint.point?.totalSpeed.metersPerSecondToKMH, for: .tVel)
        case .alt: return convertValue(main.selectedMeasurePoint.point?.altitude, for: .alt)
        case .glide: return main.selectedMeasurePoint.point?.glideRatio
        case .dive: return main.selectedMeasurePoint.point?.diveAngle
        case .hDist: return convertValue(main.selectedMeasurePoint.point?.distance2D, for: .hDist)
        case .accelVertical: return convertValue(main.selectedMeasurePoint.point?.accelVert, for: .accelVertical)
        case .accelParallel: return convertValue(main.selectedMeasurePoint.point?.accelParallel, for: .accelParallel)
        case .accelPerp: return convertValue(main.selectedMeasurePoint.point?.accelPerp, for: .accelPerp)
        case .accelTotal: return convertValue(main.selectedMeasurePoint.point?.accelTotal, for: .accelTotal)
        }
    }

    var body: some View {
            GeometryReader { g in
                VStack {
                    Text(stat.shortLabel)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    let value = main.selectedMeasurePoint.isActive
                        ? (highlightedValue ?? 0) - (measurementBaseValue ?? 0)
                        : (highlightedValue ?? 0)

                    if showValue {
                        Text(String(format: "%.2f", value))
                            .foregroundColor(Color(stat.color))
                            .font(.system(size: g.size.height / 4 + 10))
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.4)
                    } else {
                        Text(unitString)
                            .foregroundColor(Color(stat.color))
                            .font(.system(size: g.size.height / 4 + 10))
                            .lineLimit(1)
                            .allowsTightening(true)
                            .minimumScaleFactor(0.4)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
        }
    }
