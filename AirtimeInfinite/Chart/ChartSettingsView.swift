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
    
    @State private var showUnitSubmenu = false

    // You might want to keep these custom units inside your MainProcessor or here temporarily:
    @State private var altitudeUnit: UnitLength = .meters  // or your enum
    @State private var speedUnit: UnitSpeed = .kilometersPerHour
    @State private var distanceUnit: UnitLength = .meters

    
    var body: some View {
        
        VStack {
            ScrollView {
                VStack {
                    
                    HStack {
                        Text("Display Data")
                            .font(.system(.title))
                            .padding(.top)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    VStack(spacing: 0) {
                        Divider()
                        ForEach(main.chartViewProcessor.chartableMetrics.indices, id: \.self) { i in
                            VStack(spacing: 0) {
                                Toggle(isOn: self.$main.chartViewProcessor.chartableMetrics[i].isSelected) {
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
                    
                    HStack {
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
                        Toggle(isOn: $main.chartViewProcessor.autoScaleEnabled) {
                            Text("AutoScale Y-Axis")
                        }
                        .toggleStyle(CheckmarkToggleStyle())
                        .padding(.horizontal)
                        .frame(height: 40)
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Cut track")
                                .padding(.horizontal)
                            Spacer()
                            Picker("", selection: $main.autoCutTrackOption) {
                                ForEach(MainProcessor.AutoCutTrackOption.allCases) { option in
                                        Text(option.displayText).tag(option)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, -6)
                        }
                        .padding(.horizontal)
                        .frame(height: 40)

                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                        .onChange(of: main.autoCutTrackOption) { newValue in
                            main.fullyReloadTrack()
                        }
                        
                        HStack {
                            Text("Units")
                                .padding(.horizontal)
                            Spacer()

                            Menu {
                                ForEach(MainProcessor.UnitPreference.allCases) { option in
                                    Button(action: {
                                        if main.unitPreference == option {
                                            if option == .mix {
                                                showUnitSubmenu.toggle()
                                            }
                                        } else {
                                            main.unitPreference = option
                                            showUnitSubmenu = (option == .mix)
                                            main.fullyReloadTrack()
                                        }
                                    }) {
                                        Text(option.displayText)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) { // Reduce spacing here
                                    Text(main.unitPreference.displayText)
                                    
                                    VStack(spacing: 0) {
                                        Image(systemName: "chevron.up")
                                        Image(systemName: "chevron.down")
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.trailing, 6)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                        }
                        .padding(.horizontal)
                        .frame(height: 40)

                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                            .onChange(of: main.unitPreference) { newValue in
                                main.fullyReloadTrack()
                            }

                        Toggle(isOn: $main.showAcceleration) {
                            Text("Display Acceleration Data")
                        }
                        .toggleStyle(CheckmarkToggleStyle())
                        .padding(.horizontal)
                        .frame(height: 40)
                        Divider()
                            .frame(height: 1)
                            .padding(.horizontal)
                        
                        Toggle(isOn: $main.useBluetooth) {
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
        .overlay(
            Group {
                if showUnitSubmenu {
                    // Dimmed background behind the submenu
                    Color.gray.opacity(0.7)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(5) // Below the overlay content

                    VStack(spacing: 20) {
                        Text("Custom Units")
                            .font(.headline)
                            .padding(.top)

                        // Altitude picker
                        HStack {
                            Text("Altitude")
                            Spacer()
                            Picker("", selection: $altitudeUnit) {
                                Text("Meters").tag(UnitLength.meters)
                                Text("Feet").tag(UnitLength.feet)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                        .padding(.horizontal)

                        // Speed picker
                        HStack {
                            Text("Speed")
                            Spacer()
                            Picker("", selection: $speedUnit) {
                                Text("km/h").tag(UnitSpeed.kilometersPerHour)
                                Text("mph").tag(UnitSpeed.milesPerHour)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                        .padding(.horizontal)

                        // Distance picker
                        HStack {
                            Text("Distance")
                            Spacer()
                            Picker("", selection: $distanceUnit) {
                                Text("Meters").tag(UnitLength.meters)
                                Text("Feet").tag(UnitLength.feet)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                        .padding(.horizontal)

                        Button("Done") {
                            main.setCustomUnits(
                                altitude: altitudeUnit,
                                speed: speedUnit,
                                distance: distanceUnit
                            )
                            showUnitSubmenu = false
                            main.fullyReloadTrack()
                        }
                        .padding()
                    }
                    .frame(maxWidth: 350)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 20)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)  // Ensure overlay is on top
                }
            }
        )
    }
}

/// Provides a checkmark when a metric is selected as visible
struct CheckmarkToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        Button(action: { withAnimation { configuration.$isOn.wrappedValue.toggle() } }) {
            HStack {
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

extension MainProcessor.AutoCutTrackOption {
    var displayText: String {
        switch self {
        case .jump:
            return "Exit to Landing"
        default:
            return self.rawValue
        }
    }
}
extension MainProcessor.UnitPreference {
    var displayText: String {
        switch self {
        case .mix:
            return "Custom"
        default:
            return self.rawValue
        }
    }
}
