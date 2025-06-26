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
                    VStack {
                        DataPointRow(flightStats: multiRow1, showValues: $showValues)
                            .frame(height: 40)
                        Divider().frame(height: 5)
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
            main.selectedMeasurePoint.point?.accelVert.metersToFeet :
            main.selectedMeasurePoint.point?.accelVert
        case .accelParallel: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.accelParallel.metersToFeet :
            main.selectedMeasurePoint.point?.accelParallel
        case .accelPerp: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.accelPerp.metersToFeet :
            main.selectedMeasurePoint.point?.accelPerp
        case .accelTotal: return main.useImperialUnits ?
            main.selectedMeasurePoint.point?.accelTotal.metersToFeet :
            main.selectedMeasurePoint.point?.accelTotal
        }
    }

    var unitString: String {
        main.useImperialUnits ? stat.imperialUnit : stat.metricUnit
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

