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
    @State private var analysisResult: (
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
    )? = nil

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

                if let result = analysisResult {
                    let speedToShow = main.useImperialUnits ? result.maxAvgDescentSpeedmph : result.maxAvgDescentSpeedkmh
                    let unitLabel = main.useImperialUnits ? "mph" : "km/h"

                    Group {
                        HStack {
                            Text("Exit altitude:")
                            Spacer()
                            Text(formatAltitude(result.performanceWindowStartAltitude))
                        }
                        HStack {
                            Text("Validation window starts at:")
                            Spacer()
                            Text(formatAltitude(result.validationWindowStartAltitude))
                        }
                        HStack {
                            Text("End scoring window at:")
                            Spacer()
                            Text(formatAltitude(result.performanceWindowEndAltitude))
                        }
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.leading)

                    Text(String(format: "Speed Score: %.2f %@", speedToShow, unitLabel))
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 8)

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

                    if let elevation = result.localGroundElevation {
                        HStack {
                            Text("Local Ground Elevation:")
                            Spacer()
                            Text(formatAltitude(elevation))
                        }
                        .font(.subheadline)
                        .padding(.top, 6)
                    }

                } else {
                    Text("Loading speed analysis...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .offset(y: -60)
            .onChange(of: main.trackLoadedSuccessfully) { loaded in
                print("trackLoadedSuccessfully changed to \(loaded)")
                if loaded {
                    Task {
                        analysisResult = await SpeedAnalysis.fastestAverageDescentSpeedInPerformanceWindow(data: main.track.trackData)
                    }
                } else {
                    analysisResult = nil
                }
            }
        }
        // Added .task to load analysis when view appears
        .task {
            guard !main.track.trackData.isEmpty else { return }
            analysisResult = await SpeedAnalysis.fastestAverageDescentSpeedInPerformanceWindow(data: main.track.trackData)
        }
    }
}
