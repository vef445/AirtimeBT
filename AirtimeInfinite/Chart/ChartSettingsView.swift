//
//  ChartSettingsView.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Menu to select the settings and visible y-axis/FlightMetric items on the chart
struct ChartSettingsView: View {
    
    @EnvironmentObject var main: MainProcessor
    @Binding var showingMetricSelectionMenu: Bool
    
    var body: some View {
        VStack(){
            ScrollView() {
                VStack() {
                    
                    HStack() {
                        Text("Display Data")
                            .font(.system(.title))
                            .padding(.top)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    VStack(spacing: 0) {
                        Divider()
                        ForEach(main.chartViewProcessor.chartableMetrics.indices, id: \.self){ i in
                            VStack(spacing: 0) {
                                Toggle(isOn: self.$main.chartViewProcessor.chartableMetrics[i].isSelected){
                                    Text(self.main.chartViewProcessor.chartableMetrics[i].attributes.title)
                                }
                                .toggleStyle(CheckmarkToggleStyle())
                                .frame(height: 40)
                                Divider()
                                    .frame(height: 1)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack() {
                        Text("Settings")
                            .font(.system(.title))
                            .padding(.top)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    VStack(spacing: 0) {
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                        Toggle(isOn: $main.chartViewProcessor.autoScaleEnabled){
                            Text("AutoScale Y-Axis")
                        }
                        .toggleStyle(CheckmarkToggleStyle())
                        .padding(.horizontal)
                        .frame(height: 40)
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                        Toggle(isOn: $main.useImperialUnits){
                            Text("Imperial Units")
                        }
                        .toggleStyle(CheckmarkToggleStyle())
                        .padding(.horizontal)
                        .frame(height: 40)
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                        Toggle(isOn: $main.showAcceleration){
                            Text("Display Acceleration Data")
                        }
                        .toggleStyle(CheckmarkToggleStyle())
                        .padding(.horizontal)
                        .frame(height: 40)
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                        Toggle(isOn: $main.useBluetooth){
                            Text("Connect via Bluetooth")
                        }
                        .toggleStyle(CheckmarkToggleStyle())
                        .padding(.horizontal)
                        .frame(height: 40)
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                    }
                }
            }
            Button(action: {
                self.showingMetricSelectionMenu = false
                self.main.chartViewProcessor.updateAutoScaleAxis()
                self.main.chartViewProcessor.reloadTrack()
            }) {
                Text("Close")
            }
            .padding()
        }
        .frame(
            height: min(
                UIScreen.main.bounds.height - 100,
                650 // TODO: Update this to be dynamic
            )
        )
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

