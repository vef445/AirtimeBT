//
//  SpeedView.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 27/06/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import SwiftUI
import DGCharts

struct FastestDescentSpeedView: View {
    @EnvironmentObject var main: MainProcessor
    
    func formatAltitude(_ meters: Double) -> String {
        if main.useImperialUnits {
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        } else {
            return String(format: "%.0f m", meters)
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 10) {
                Text("Speed Run Analysis")
                    .font(.headline)
                    .padding(.top, 6)

                if let result = SpeedAnalysis.fastestAverageDescentSpeedInPerformanceWindow(
                    data: main.track.trackData,
                    windowDuration: 3.0
                ) {
                    let speedToShow = main.useImperialUnits ? result.maxAvgDescentSpeedmph : result.maxAvgDescentSpeedkmh
                    let unitLabel = main.useImperialUnits ? "mph" : "km/h"

                    Group {
                        HStack {
                            Text("Performance Window Start Altitude:")
                            Spacer()
                            Text(formatAltitude(result.performanceWindowStartAltitude))
                        }
                        HStack {
                            Text("Performance Window End Altitude:")
                            Spacer()
                            Text(formatAltitude(result.performanceWindowEndAltitude))
                        }
                        HStack {
                            Text("Validation Window Start Altitude:")
                            Spacer()
                            Text(formatAltitude(result.validationWindowStartAltitude))
                        }
                        HStack {
                            Text("Validation Window End Altitude:")
                            Spacer()
                            Text(formatAltitude(result.validationWindowEndAltitude))
                        }
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)

                    Text(String(format: "Speed Score: %.2f %@", speedToShow, unitLabel))
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 8)

                    // Speed accuracy info:
                    VStack(spacing: 4) {
                        HStack {
                            Text("Average Speed Tracking Error:")
                            Spacer()
                            Text(String(format: "%.2f m/s", result.averageSpeedAccuracy))
                        }
                        .font(.subheadline)

                        HStack {
                            Text("Max Speed Tracking Error:")
                            Spacer()
                            Text(String(format: "%.2f m/s", result.maxSpeedAccuracy))
                                .foregroundColor(result.maxSpeedAccuracy > 3 ? .red : .primary)
                        }
                        .font(.subheadline)

                        if result.maxSpeedAccuracy > 3 {
                            Text("⚠️ Speed Tracking Error exceeds 3 m/s!")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)

                } else {
                    Text("No valid descent speed data")
                }
            }
            .padding()
            .offset(y: -60)
        }
    }
}
