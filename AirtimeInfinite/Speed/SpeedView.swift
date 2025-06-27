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
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Fastest Average Descent Speed Over 3sec")
                .font(.headline)
            
            if let result = SpeedAnalysis.fastestAverageDescentSpeed(
                data: main.track.trackData,
                windowDuration: 3.0,
                minAltitude: 1700.0
            ) {
                let speedToShow = main.useImperialUnits ? result.maxAvgDescentSpeedmph : result.maxAvgDescentSpeedkmh
                let unitLabel = main.useImperialUnits ? "mph" : "km/h"
                
                Text("Start Time: \(result.startTime) sec")
                Text(String(format: "Speed: %.2f %@", speedToShow, unitLabel))
            } else {
                Text("No valid descent speed data")
            }
        }
        .padding()
        .offset(y: -60)
        .background(Color(.systemBackground))
    }
}

