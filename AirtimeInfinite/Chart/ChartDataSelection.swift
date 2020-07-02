//
//  ChartDataSelection.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Menu to select the visible y-axis/FlightMetric items on the chart
struct ChartDataSelectionView: View {
    
    @EnvironmentObject var chartViewProcessor: ChartViewProcessor
    @Binding var showingMetricSelectionMenu: Bool
    
    var body: some View {
        VStack() {
            VStack(spacing: 0) {
                Divider()
                ForEach(chartViewProcessor.chartableMetrics.indices){ i in
                    VStack(spacing: 0) {
                        Toggle(isOn: self.$chartViewProcessor.chartableMetrics[i].isSelected){
                            Text(self.chartViewProcessor.chartableMetrics[i].attributes.title)
                        }
                        .toggleStyle(CheckmarkToggleStyle())
                        .frame(height: 40)
                        Divider()
                            .frame(height: 1)
                    }
                }
            }
            .padding()
            Button(action: {
                self.showingMetricSelectionMenu = false
                self.chartViewProcessor.reloadTrack()
            }) {
                Text("Close")
            }
            .padding()
        }
    }
}

/// Provides a checkmark when a metric is selected as visible
struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        Button(action: { withAnimation { configuration.$isOn.wrappedValue.toggle() }}){
            HStack{
                configuration.label.foregroundColor(.primary)
                Spacer()
                if configuration.isOn {
                    Image(systemName: "checkmark").foregroundColor(.blue)
                        .padding(0)
                }
            }.padding()
        }
        .frame(height: 30.0)
        .padding(0)
    }
}

